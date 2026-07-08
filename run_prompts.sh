#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# USAGE_START
# run_prompts.sh — runner for the paper-factory prompt pipeline (prompts/step*.txt)
#
# Feeds each pipeline step to a FRESH model session (Claude or Codex), substituting
# placeholders (__RESEARCH_QUESTION__, __PROJECT_PATH__, __AUTHOR__, __N__, __LENS__),
# fanning out the parallel steps, and honoring the KILL / REOPEN gates. Each step is
# self-contained; context flows only through files on disk.
#
# Usage:
#   ./run_prompts.sh [project_dir]            Run / resume the pipeline
#   ./run_prompts.sh --status [project_dir]   Show step status
#   ./run_prompts.sh --step  <id> [dir]       Run a single step (ignores markers)
#   ./run_prompts.sh --from  <id> [dir]       Run from a step onward
#   ./run_prompts.sh --dry-run --step <id>    Print the filled prompt; no model call
#   ./run_prompts.sh --help
#
# Flags: --auto (no pause between steps) · --parallel (fan-out/dual concurrently)
#        --skip-codex (route codex steps to Claude) · --dry-run
#
# Env: CLAUDE_BIN (default: claude), CODEX_BIN (default: codex),
#      STEP_TIMEOUT (default 2700s), LENS_ONLY (subset of lens numbers, e.g. "2 4")
# USAGE_END
# ─────────────────────────────────────────────────────────────────────────────

FACTORY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$FACTORY/prompts"
CLAUDE_BIN="${CLAUDE_BIN:-claude}"
CODEX_BIN="${CODEX_BIN:-codex}"
CODEX_SANDBOX="${CODEX_SANDBOX:-workspace-write}"   # codex exec write scope
TIMEOUT_BIN="$(command -v gtimeout || command -v timeout || true)"  # cap per-step runtime
STEP_TIMEOUT="${STEP_TIMEOUT:-2700}"                # seconds per step; guards non-exiting sessions
MAX_REOPEN=3

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

# id | promptspec | engine | fanout | gate
#   promptspec: prompt basename, or DUAL/EXT/LENS (special) ; engine: claude|codex|dual
#   fanout: none|ext7|lens5|n5 ; gate: none|kill|reopen
STEPS=(
  "1a|step1a_deep_research|codex|none|none"
  "1b|step1b_data_wrangle|claude|none|none"
  "1c|step1c_key_variables|claude|none|none"
  "1d|step1d_viability_gate|claude|none|kill"
  "1e|step1e_descriptive_map|claude|none|none"
  "2|DUAL|dual|none|none"
  "3|step3_synthesis|claude|none|none"
  "4ext|EXT|claude|ext7|none"
  "4lens|LENS|claude|lens5|none"
  "4review|step4_architect_review|claude|n5|none"
  "4audit|step4_auditor|claude|none|none"
  "4decide|step4_decider|claude|none|none"
  "4exec|step4_executor|claude|none|none"
  "5argres|step5_argument_research|claude|none|none"
  "5audit|step5_data_audit|claude|none|none"
  "6|step6_methods_audit|claude|none|none"
  "7|step7_paper_writer|claude|none|none"
  "8|step8_code_review|claude|none|none"
  "9|step9_review|claude|none|none"
  "10|step10_revision|claude|none|none"
  "11|step11_final_review|claude|none|reopen"
  "12|step12_citation_audit|claude|none|none"
  "13|step13_table_formatting|claude|none|none"
  "14|step14_abstract|claude|none|none"
  "15|step15_derobotification|claude|none|none"
)

usage() { awk '/^# USAGE_START/{f=1;next} /^# USAGE_END/{f=0} f' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

# ── Research question (single source of truth: project_brief.md) ─────────────
extract_rq() {
  [[ -f project_brief.md ]] || return 1
  awk '/^## Research Question/{f=1;next} /^## /{f=0} f' project_brief.md \
    | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//'
}

# ── Author (optional; substituted as __AUTHOR__ into the manuscript front matter) ──
extract_author() {
  [[ -f project_brief.md ]] || return 1
  awk '/^## Author/{f=1;next} /^## /{f=0} f' project_brief.md \
    | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//' | head -1
}

# ── Helpers ──────────────────────────────────────────────────────────────────
step_field() { echo "$1" | cut -d'|' -f"$2"; }
step_index() { local id="$1" i; for i in "${!STEPS[@]}"; do [[ "$(step_field "${STEPS[$i]}" 1)" == "$id" ]] && { echo "$i"; return; }; done; echo -1; }
marker() { echo "$MARKER_DIR/$1.done"; }

# Mechanical completion check (spec §5.4): a step is "done" only when its deliverable(s)
# actually exist — not merely because the session exited 0.
_wait_all() {  # PIDs… → 0 if all background jobs succeeded, 1 if any failed
  local pid rc=0
  for pid in "$@"; do [[ -n "$pid" ]] || continue; wait "$pid" || rc=1; done
  return $rc
}
_glob_count() {  # <prefix> <count> → 0 if ≥count files like <prefix>[1-9]*.md exist
  local prefix="$1" expected="$2" n=0 f
  for f in ${prefix}[1-9]*.md; do [[ -f "$f" ]] && n=$((n+1)); done
  if [[ "$n" -lt "$expected" ]]; then
    echo -e "${RED}✗ fan-out incomplete: found $n/$expected ${prefix}[1-9]*.md${NC}" >&2; return 1
  fi
  return 0
}
step_check() {  # id → 0 if all expected deliverables present, else 1 (+ message)
  local id="$1" out="" f rc=0
  case "$id" in
    1a) out="codex_research.md" ;;    1b) out="data_wrangle.md" ;;
    1c) out="key_variables.md" ;;     1d) out="viability_gate.md" ;;
    1e) out="descriptive_map.md" ;;   2)  out="findings_brief_claude.md findings_brief_codex.md" ;;
    3)  out="findings_brief.md" ;;
    4ext)    _glob_count "extension_brief_" 7;   return $? ;;
    4lens)   _glob_count "paper_map_" 5;         return $? ;;
    4review) _glob_count "paper_map_review_" 5;  return $? ;;
    4audit)  out="proposal_audit.md" ;;   4decide) out="argument_decision.md" ;;
    5argres) out="argument_research.md" ;;
    7)  out="sample_support.md dropped_findings.md" ;;
    8)  out="code_review.md" ;;        9)  out="review_comments.md" ;;
    10) out="revision_summary.md" ;;   11) out="final_review.md" ;;
    12) out="citation_audit.md" ;;     13) out="table_formatting.md" ;;
    14) out="abstract_draft.md" ;;     15) out="derobotification.md" ;;
    *)  out="" ;;   # 4exec/5audit/6 mutate scripts or append to findings_brief.md → exit-code only
  esac
  for f in $out; do
    [[ -f "$f" ]] || { echo -e "${RED}✗ step $id: missing deliverable $f${NC}" >&2; rc=1; }
  done
  return $rc
}

# Gate parsing — line-1 only (spec §5.4); factored out so they are unit-testable.
kill_triggered()   { [[ -f viability_gate.md ]] && head -1 viability_gate.md | grep -q "^VERDICT: KILL"; }
reopen_triggered() { [[ -f final_review.md   ]] && head -1 final_review.md   | grep -q "^VERDICT: REOPEN_STEP10"; }

# Mechanical number gate (spec §5.4/§6.3): at the review/polish steps the RUNNER — not the
# model — checks that no naked numeral slipped into manuscript prose. Loud + logged, never silent.
number_gate() {
  case "$1" in 8|11|15) ;; *) return 0 ;; esac
  local lint="$FACTORY/scripts/python/lint_prose_numbers.py"
  [[ -f "$lint" ]] && compgen -G "manuscript/*.qmd" >/dev/null || return 0
  if python3 "$lint" manuscript/*.qmd; then
    echo -e "${GREEN}✓ number-gate (step $1): no naked numerals in prose${NC}"
  else
    echo -e "${RED}⚠ number-gate (step $1): naked numerals in prose — convert to inline \`r stats\$…\$lab\` lookups (spec §6.3)${NC}"
  fi
}

lens_text() {  # extract the LENS_N block from step4_architect_lenses.txt
  awk -v s="---LENS_${1}---" '$0==s{f=1;next} /^---/{f=0} f' "$PROMPTS_DIR/step4_architect_lenses.txt"
}

fill_prompt() {  # promptfile [N] [LENS]
  local content; content="$(cat "$1")"
  content="${content//__RESEARCH_QUESTION__/$RESEARCH_QUESTION}"
  content="${content//__PROJECT_PATH__/$PROJECT_DIR_ABS}"
  content="${content//__AUTHOR__/$AUTHOR}"
  [[ -n "${2:-}" ]] && content="${content//__N__/$2}"
  [[ -n "${3:-}" ]] && content="${content//__LENS__/$3}"
  # Mechanical gate (spec §5.4): never run a step with an unresolved __PLACEHOLDER__.
  if grep -qE '__[A-Z_]+__' <<<"$content"; then
    echo "fill_prompt: unresolved placeholder(s) in $1: $(grep -oE '__[A-Z_]+__' <<<"$content" | sort -u | tr '\n' ' ')" >&2
    return 1
  fi
  printf '%s' "$content"
}

resolve_engine() {  # engine -> effective engine (handles --skip-codex)
  local e="$1"
  if [[ "$e" == "codex" && "$SKIP_CODEX" == true ]]; then echo "claude"; else echo "$e"; fi
}

run_one() {  # promptfile engine logname [N] [LENS]
  local file="$1" engine; engine="$(resolve_engine "$2")"; local logname="$3"
  local prompt; prompt="$(fill_prompt "$file" "${4:-}" "${5:-}")"
  local log="$LOG_DIR/${logname}_$(date +%Y%m%d_%H%M%S).log"
  local cmd="$CLAUDE_BIN --print --permission-mode acceptEdits"
  [[ "$engine" == "codex" ]] && cmd="$CODEX_BIN exec --sandbox $CODEX_SANDBOX --color never"
  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[dry-run]${NC} $logname  →  $cmd <$(basename "$file")>"
    printf '%s\n' "$prompt" | sed 's/^/    │ /' | head -25
    echo "    └ … ($(printf '%s' "$prompt" | wc -l | tr -d ' ') lines total)"
    return 0
  fi
  if [[ "$engine" == "codex" ]] && ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
    echo -e "${RED}codex not found.${NC} Install + authenticate it, or re-run with --skip-codex."; exit 1
  fi
  local TO=""; [[ -n "$TIMEOUT_BIN" ]] && TO="$TIMEOUT_BIN $STEP_TIMEOUT"
  echo -e "${BLUE}▶ $logname${NC} (engine=$engine, cap=${STEP_TIMEOUT}s) → $log"
  # stdin from /dev/null so non-interactive runs never block; gtimeout caps a hung session.
  case "$engine" in
    claude) $TO "$CLAUDE_BIN" --print --permission-mode acceptEdits "$prompt" </dev/null 2>&1 | tee "$log"; return "${PIPESTATUS[0]}" ;;
    codex)  $TO "$CODEX_BIN" exec --sandbox "$CODEX_SANDBOX" --color never "$prompt" </dev/null 2>&1 | tee "$log"; return "${PIPESTATUS[0]}" ;;
  esac
}

run_step() {  # the full step record "id|spec|engine|fanout|gate"
  local rec="$1"
  local id spec engine fanout
  id="$(step_field "$rec" 1)"; spec="$(step_field "$rec" 2)"
  engine="$(step_field "$rec" 3)"; fanout="$(step_field "$rec" 4)"
  echo -e "\n${GREEN}━━━ Step $id ━━━${NC}"
  case "$fanout" in
    none)
      if [[ "$spec" == "DUAL" ]]; then
        if [[ "$PARALLEL" == true ]]; then
          local pids=()
          run_one "$PROMPTS_DIR/step2_claude_analyst.txt" claude "2_claude" & pids+=($!)
          run_one "$PROMPTS_DIR/step2_codex_analyst.txt"  codex  "2_codex"  & pids+=($!)
          _wait_all "${pids[@]}" || return 1
        else
          run_one "$PROMPTS_DIR/step2_claude_analyst.txt" claude "2_claude"
          run_one "$PROMPTS_DIR/step2_codex_analyst.txt"  codex  "2_codex"
        fi
      else
        run_one "$PROMPTS_DIR/${spec}.txt" "$engine" "$id"
      fi
      ;;
    ext7)
      local f pids=()
      for f in "$PROMPTS_DIR"/step4_ext*.txt; do
        if [[ "$PARALLEL" == true ]]; then run_one "$f" claude "4ext_$(basename "$f" .txt)" & pids+=($!)
        else run_one "$f" claude "4ext_$(basename "$f" .txt)"; fi
      done
      [[ "$PARALLEL" == true ]] && { _wait_all "${pids[@]}" || return 1; }
      ;;
    lens5)
      local n pids=()
      for n in ${LENS_ONLY:-1 2 3 4 5}; do
        if [[ "$PARALLEL" == true ]]; then run_one "$PROMPTS_DIR/step4_architect.txt" claude "4lens_$n" "$n" "$(lens_text "$n")" & pids+=($!)
        else run_one "$PROMPTS_DIR/step4_architect.txt" claude "4lens_$n" "$n" "$(lens_text "$n")"; fi
      done
      [[ "$PARALLEL" == true ]] && { _wait_all "${pids[@]}" || return 1; }
      ;;
    n5)
      local n pids=()
      for n in ${LENS_ONLY:-1 2 3 4 5}; do
        if [[ "$PARALLEL" == true ]]; then run_one "$PROMPTS_DIR/${spec}.txt" claude "4review_$n" "$n" & pids+=($!)
        else run_one "$PROMPTS_DIR/${spec}.txt" claude "4review_$n" "$n"; fi
      done
      [[ "$PARALLEL" == true ]] && { _wait_all "${pids[@]}" || return 1; }
      ;;
  esac
  if [[ "$DRY_RUN" != true ]]; then
    if ! step_check "$id"; then
      echo -e "${RED}✗ step $id incomplete — not marking done (re-run to resume)${NC}"; return 1
    fi
    touch "$(marker "$id")"
    number_gate "$id"
    # Clean-final-render guard (spec §5.4): after the last prose pass, invalidate the Quarto
    # freeze cache so the final render re-executes and cannot serve stale numbers.
    [[ "$id" == 15 ]] && rm -rf manuscript/_freeze 2>/dev/null
  fi
}

# ── Executable entry point ───────────────────────────────────────────────────
# When sourced (e.g. by tests/) stop here — the functions above are all tests need.
[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0

# ── Argument parsing ─────────────────────────────────────────────────────────
MODE="run"; TARGET=""; AUTO=false; PARALLEL=false; SKIP_CODEX=false; DRY_RUN=false
PROJECT_DIR="."
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)   usage ;;
    --status)    MODE="status"; shift ;;
    --step)      MODE="step"; TARGET="${2:?--step needs an id}"; shift 2 ;;
    --from)      MODE="from"; TARGET="${2:?--from needs an id}"; shift 2 ;;
    --auto)      AUTO=true; shift ;;
    --parallel)  PARALLEL=true; shift ;;
    --skip-codex) SKIP_CODEX=true; shift ;;
    --dry-run)   DRY_RUN=true; shift ;;
    *)           PROJECT_DIR="$1"; shift ;;
  esac
done

[[ -d "$PROJECT_DIR" ]] || { echo -e "${RED}Not a directory: $PROJECT_DIR${NC}"; exit 1; }
cd "$PROJECT_DIR"
PROJECT_DIR_ABS="$(pwd)"
MARKER_DIR="$PROJECT_DIR_ABS/run_state/factory"
LOG_DIR="$PROJECT_DIR_ABS/logs/factory"
mkdir -p "$MARKER_DIR" "$LOG_DIR"
RESEARCH_QUESTION="$(extract_rq || true)"
AUTHOR="$(extract_author || true)"

# ── Status ───────────────────────────────────────────────────────────────────
if [[ "$MODE" == "status" ]]; then
  echo -e "${BLUE}Project:${NC} $PROJECT_DIR_ABS"
  [[ -n "$RESEARCH_QUESTION" ]] && echo -e "${BLUE}Research question:${NC} $(echo "$RESEARCH_QUESTION" | head -1)" \
    || echo -e "${RED}No project_brief.md / ## Research Question found.${NC}"
  echo -e "\n${BLUE}Steps:${NC}"
  for rec in "${STEPS[@]}"; do
    id="$(step_field "$rec" 1)"; spec="$(step_field "$rec" 2)"; engine="$(step_field "$rec" 3)"; gate="$(step_field "$rec" 5)"
    if [[ -f "$(marker "$id")" ]]; then mark="${GREEN}✓${NC}"; else mark="${RED}·${NC}"; fi
    g=""; [[ "$gate" != none ]] && g=" ${YELLOW}[gate:$gate]${NC}"
    printf "  %b %-8s %-26s %s%b\n" "$mark" "$id" "$spec" "$engine" "$g"
  done
  exit 0
fi

# ── Preconditions for a real run ─────────────────────────────────────────────
if [[ "$DRY_RUN" != true ]]; then
  [[ -f project_brief.md ]] || { echo -e "${RED}project_brief.md missing — create it first.${NC}"; exit 1; }
  [[ -n "$RESEARCH_QUESTION" ]] || { echo -e "${RED}No '## Research Question' section in project_brief.md.${NC}"; exit 1; }
fi

# ── Single step ──────────────────────────────────────────────────────────────
if [[ "$MODE" == "step" ]]; then
  idx="$(step_index "$TARGET")"; [[ "$idx" -ge 0 ]] || { echo -e "${RED}Unknown step: $TARGET${NC}"; exit 1; }
  run_step "${STEPS[$idx]}"; exit 0
fi

# ── Sequential run / resume / from ───────────────────────────────────────────
start=0
if [[ "$MODE" == "from" ]]; then
  start="$(step_index "$TARGET")"; [[ "$start" -ge 0 ]] || { echo -e "${RED}Unknown step: $TARGET${NC}"; exit 1; }
fi

reopen_cycles=0
i="$start"
while [[ "$i" -lt "${#STEPS[@]}" ]]; do
  rec="${STEPS[$i]}"; id="$(step_field "$rec" 1)"; gate="$(step_field "$rec" 5)"
  # Resume: skip completed steps (unless --from forced a start point at/after here)
  if [[ "$MODE" == "run" && -f "$(marker "$id")" ]]; then
    echo -e "${YELLOW}✓ skip $id (done)${NC}"; i=$((i+1)); continue
  fi
  # Gate steps: clear any stale verdict file so a prior run's verdict can't leak in.
  [[ "$gate" == "kill"   ]] && rm -f viability_gate.md
  [[ "$gate" == "reopen" ]] && rm -f final_review.md
  run_step "$rec"
  # Gates — parse the FIRST line only (spec §5.4); a verdict buried in prose must not (mis)fire.
  if [[ "$gate" == "kill" ]] && kill_triggered; then
    echo -e "\n${RED}Project KILLED at viability gate. See kill_memo.md.${NC}"; exit 1
  fi
  if [[ "$gate" == "reopen" ]] && reopen_triggered; then
    if [[ "$reopen_cycles" -lt "$MAX_REOPEN" ]]; then
      reopen_cycles=$((reopen_cycles+1))
      echo -e "${YELLOW}Final review: REOPEN (cycle $reopen_cycles/$MAX_REOPEN) — re-running step 10 → 11${NC}"
      touch "$PROJECT_DIR_ABS/.step11_reopen_to_step10"
      rm -f "$(marker 10)" "$(marker 11)"
      i="$(step_index 10)"; continue
    fi
    # Spec §5.4: never polish (steps 12–15) a paper that still carries a REOPEN verdict.
    echo -e "\n${RED}Max reopen cycles ($MAX_REOPEN) reached with an unresolved REOPEN verdict.${NC}"
    echo -e "${RED}Halting for human review — the polish steps must not run on unresolved blocking issues.${NC}"; exit 1
  fi
  [[ "$gate" == "reopen" ]] && rm -f "$PROJECT_DIR_ABS/.step11_reopen_to_step10"
  if [[ "$AUTO" != true && "$DRY_RUN" != true ]]; then
    read -rp $'\nStep complete. Enter to continue (Ctrl-C to stop)… '
  fi
  i=$((i+1))
done

echo -e "\n${GREEN}Pipeline complete.${NC}"
