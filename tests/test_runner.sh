#!/usr/bin/env bash
# Unit tests for run_prompts.sh mechanical gates (spec §5.4).
# Sources the runner (which returns early when sourced) to test its pure functions
# against fixtures. Each gate must fail LOUDLY, never pass silently.

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
# shellcheck source=/dev/null
source "$ROOT/run_prompts.sh"     # early-returns when sourced → defines functions only
set +e +u                          # tests manage their own exit codes

pass=0; fail=0
ok()  { echo "  ok  — $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL — $1"; fail=$((fail + 1)); }

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1
PROJECT_DIR_ABS="$WORK"; RED=""; GREEN=""; YELLOW=""; BLUE=""; NC=""

echo "1) fill_prompt — unresolved-placeholder guard"
RESEARCH_QUESTION="Does X cause Y?"; AUTHOR=""
printf 'RQ: __RESEARCH_QUESTION__ at __PROJECT_PATH__\n' > good.txt
printf 'RQ: __RESEARCH_QUESTION__ and __MYSTERY__\n'      > bad.txt
fill_prompt good.txt >/dev/null 2>&1 && ok "fully-resolved prompt passes"      || bad "resolved prompt should pass"
fill_prompt bad.txt  >/dev/null 2>&1 && bad "unresolved __MYSTERY__ should abort" || ok "unresolved placeholder aborts"

echo "2) step_check — fan-out completeness counts"
for i in 1 2 3 4 5 6; do : > "extension_brief_$i.md"; done
step_check 4ext >/dev/null 2>&1 && bad "6/7 briefs should fail" || ok "partial fan-out (6/7 briefs) fails"
: > extension_brief_7.md
step_check 4ext >/dev/null 2>&1 && ok "7/7 briefs pass"        || bad "complete fan-out should pass"
for i in 1 2 3 4 5; do : > "paper_map_$i.md"; : > "paper_map_review_$i.md"; done
step_check 4lens   >/dev/null 2>&1 && ok "4lens counts paper_map_[1-5] only (not the reviews)" || bad "4lens should pass with 5 maps"
step_check 4review >/dev/null 2>&1 && ok "4review counts paper_map_review_[1-5]"               || bad "4review should pass with 5 reviews"
# DUAL step 2 requires BOTH analyst briefs
: > findings_brief_claude.md
step_check 2 >/dev/null 2>&1 && bad "one of two step-2 briefs should fail" || ok "step 2 fails with only the claude brief"
: > findings_brief_codex.md
step_check 2 >/dev/null 2>&1 && ok "step 2 passes with both briefs" || bad "step 2 should pass with both briefs"

echo "3) KILL gate — line-1 only"
printf '# Viability Gate\n\npreamble\nVERDICT: KILL\n' > viability_gate.md
kill_triggered && bad "KILL buried on line 4 must NOT trigger" || ok "buried KILL (line 4) does not trigger"
printf 'VERDICT: KILL\n\ndetails\n' > viability_gate.md
kill_triggered && ok "KILL on line 1 triggers"                 || bad "line-1 KILL should trigger"
printf 'VERDICT: PASS\n' > viability_gate.md
kill_triggered && bad "PASS must not trigger a kill"           || ok "PASS does not trigger a kill"

echo "4) REOPEN gate — line-1 only"
printf 'VERDICT: PASS_WITH_DIRECT_FIXES\n\nWe weighed REOPEN_STEP10_TEXT but resolved it inline.\n' > final_review.md
reopen_triggered && bad "prose mention of REOPEN must NOT reopen" || ok "prose-only REOPEN mention does not trigger"
printf 'VERDICT: REOPEN_STEP10_ANALYSIS\n\n...\n' > final_review.md
reopen_triggered && ok "line-1 REOPEN triggers"                  || bad "line-1 REOPEN should trigger"

echo "5) number_gate — runner-executed prose check at review/polish steps"
FACTORY="$ROOT"   # number_gate resolves the lint under $FACTORY
mkdir -p manuscript
printf '# H\n\nClean prose, Section 3.\n' > manuscript/a.qmd
number_gate 15 2>&1 | grep -q '✓ number-gate' && ok "clean prose passes the gate" || bad "clean prose should pass the gate"
printf '# H\n\nThe effect was 8.3%% here.\n' > manuscript/b.qmd
number_gate 15 2>&1 | grep -q '⚠ number-gate' && ok "naked numeral warns at the gate" || bad "naked numeral should warn"
number_gate 7  2>&1 | grep -q 'number-gate' && bad "step 7 must not be a gate step" || ok "non-gate step is a no-op"

echo
echo "── PASS=$pass  FAIL=$fail ──"
[[ "$fail" -eq 0 ]]
