#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# run_prompts.sh — runner for the WN prompt pipeline (prompts/step*.txt)
#
# Feeds each prompt-pipeline step to a FRESH model session (Claude or Codex),
# substituting placeholders (__RESEARCH_QUESTION__, __PROJECT_PATH__, __N__,
# __LENS__), fanning out the parallel steps, and honoring the KILL / REOPEN gates.
#
# This drives the PROMPT FILES, not the .claude/skills (which are the separate
# Claude-author agent pipeline). See memory: wn-prompt-pipeline-not-skills.
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
# Env: CLAUDE_BIN (default: claude), CODEX_BIN (default: codex)
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

usage() { sed -n '4,30p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

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

# ── Research question (single source of truth: project_brief.md) ─────────────
extract_rq() {
  [[ -f project_brief.md ]] || return 1
  awk '/^## Research Question/{f=1;next} /^## /{f=0} f' project_brief.md \
    | sed '/^[[:space:]]*$/d' | sed 's/^[[:space:]]*//'
}
RESEARCH_QUESTION="$(extract_rq || true)"

# ── Helpers ──────────────────────────────────────────────────────────────────
step_field() { echo "$1" | cut -d'|' -f"$2"; }
step_index() { local id="$1" i; for i in "${!STEPS[@]}"; do [[ "$(step_field "${STEPS[$i]}" 1)" == "$id" ]] && { echo "$i"; return; }; done; echo -1; }
marker() { echo "$MARKER_DIR/$1.done"; }

# Primary deliverable per step (empty = no single sentinel → fall back to exit code).
step_output() {
  case "$1" in
    1a) echo codex_research.md ;; 1b) echo data_wrangle.md ;; 1c) echo key_variables.md ;;
    1d) echo viability_gate.md ;; 1e) echo descriptive_map.md ;;
    3)  echo findings_brief.md ;; 4decide) echo argument_decision.md ;;
    *)  echo "" ;;
  esac
}

lens_text() {  # extract the LENS_N block from step4_architect_lenses.txt
  awk -v s="---LENS_${1}---" '$0==s{f=1;next} /^---/{f=0} f' "$PROMPTS_DIR/step4_architect_lenses.txt"
}

fill_prompt() {  # promptfile [N] [LENS]
  local content; content="$(cat "$1")"
  content="${content//__RESEARCH_QUESTION__/$RESEARCH_QUESTION}"
  content="${content//__PROJECT_PATH__/$PROJECT_DIR_ABS}"
  [[ -n "${2:-}" ]] && content="${content//__N__/$2}"
  [[ -n "${3:-}" ]] && content="${content//__LENS__/$3}"
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
          run_one "$PROMPTS_DIR/step2_claude_analyst.txt" claude "2_claude" &
          run_one "$PROMPTS_DIR/step2_codex_analyst.txt"  codex  "2_codex"  &
          wait
        else
          run_one "$PROMPTS_DIR/step2_claude_analyst.txt" claude "2_claude"
          run_one "$PROMPTS_DIR/step2_codex_analyst.txt"  codex  "2_codex"
        fi
      else
        run_one "$PROMPTS_DIR/${spec}.txt" "$engine" "$id"
      fi
      ;;
    ext7)
      local f
      for f in "$PROMPTS_DIR"/step4_ext*.txt; do
        if [[ "$PARALLEL" == true ]]; then run_one "$f" claude "4ext_$(basename "$f" .txt)" &
        else run_one "$f" claude "4ext_$(basename "$f" .txt)"; fi
      done
      [[ "$PARALLEL" == true ]] && wait || true
      ;;
    lens5)
      local n
      for n in ${LENS_ONLY:-1 2 3 4 5}; do
        if [[ "$PARALLEL" == true ]]; then run_one "$PROMPTS_DIR/step4_architect.txt" claude "4lens_$n" "$n" "$(lens_text "$n")" &
        else run_one "$PROMPTS_DIR/step4_architect.txt" claude "4lens_$n" "$n" "$(lens_text "$n")"; fi
      done
      [[ "$PARALLEL" == true ]] && wait || true
      ;;
    n5)
      local n
      for n in ${LENS_ONLY:-1 2 3 4 5}; do
        if [[ "$PARALLEL" == true ]]; then run_one "$PROMPTS_DIR/${spec}.txt" claude "4review_$n" "$n" &
        else run_one "$PROMPTS_DIR/${spec}.txt" claude "4review_$n" "$n"; fi
      done
      [[ "$PARALLEL" == true ]] && wait || true
      ;;
  esac
  if [[ "$DRY_RUN" != true ]]; then
    local out; out="$(step_output "$id")"
    if [[ -n "$out" && ! -f "$out" ]]; then
      echo -e "${RED}✗ step $id produced no $out — not marking done${NC}"; return 1
    fi
    touch "$(marker "$id")"
  fi
}

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
  run_step "$rec"
  # Gates
  if [[ "$gate" == "kill" && -f viability_gate.md ]] && head -3 viability_gate.md | grep -q "VERDICT: KILL"; then
    echo -e "\n${RED}Project KILLED at viability gate. See kill_memo.md.${NC}"; exit 1
  fi
  if [[ "$gate" == "reopen" && -f final_review.md ]] && grep -q "REOPEN_STEP10" final_review.md; then
    if [[ "$reopen_cycles" -lt "$MAX_REOPEN" ]]; then
      reopen_cycles=$((reopen_cycles+1))
      echo -e "${YELLOW}Final review: REOPEN (cycle $reopen_cycles/$MAX_REOPEN) — re-running step 10 → 11${NC}"
      touch "$PROJECT_DIR_ABS/.step11_reopen_to_step10"
      rm -f "$(marker 10)" "$(marker 11)"
      i="$(step_index 10)"; continue
    fi
    echo -e "${RED}Max reopen cycles reached; continuing.${NC}"
  fi
  [[ "$gate" == "reopen" ]] && rm -f "$PROJECT_DIR_ABS/.step11_reopen_to_step10"
  if [[ "$AUTO" != true && "$DRY_RUN" != true ]]; then
    read -rp $'\nStep complete. Enter to continue (Ctrl-C to stop)… '
  fi
  i=$((i+1))
done

echo -e "\n${GREEN}Pipeline complete.${NC}"
