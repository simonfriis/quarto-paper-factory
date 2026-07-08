#!/usr/bin/env bash
# Tests for scripts/python/lint_prose_numbers.py — the naked-numeral gate (spec §6.3).

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
LINT="$ROOT/scripts/python/lint_prose_numbers.py"

pass=0; fail=0
ok()  { echo "  ok  — $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL — $1"; fail=$((fail + 1)); }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# run the lint on one file, echo its exit code
run() { python3 "$LINT" "$1" >/dev/null 2>&1; echo $?; }

printf '# H\n\nThe effect was 8.3%% of the mean.\n' > "$WORK/naked.qmd"
[[ "$(run "$WORK/naked.qmd")" == 1 ]] && ok "naked '8.3%' flagged" || bad "naked percentage should flag"

printf '# H\n\nThe effect was `r stats$eff$lab` of the mean.\n' > "$WORK/inline.qmd"
[[ "$(run "$WORK/inline.qmd")" == 0 ]] && ok "inline `r` lookup passes" || bad "inline lookup should pass"

printf '# H\n\nIn 2024, Section 3 lists footnote 5; the baseline was 0.\n' > "$WORK/allow.qmd"
[[ "$(run "$WORK/allow.qmd")" == 0 ]] && ok "year / enumerator / zero allowed" || bad "allowlist should pass"

printf '# H\n\n```{r}\nx <- 42.7\n```\n\nClean prose here.\n' > "$WORK/chunk.qmd"
[[ "$(run "$WORK/chunk.qmd")" == 0 ]] && ok "code-chunk number exempt" || bad "code chunk should be exempt"

printf '# H\n\nSee `x <- 3.14`.\n<!-- note: 9.9 -->\nEquation $y = 2.5x$ holds.\n' > "$WORK/spans.qmd"
[[ "$(run "$WORK/spans.qmd")" == 0 ]] && ok "inline-code / comment / math exempt" || bad "spans should be exempt"

printf '# H\n\nThe sample had 2,357 respondents and a mean of 4.2.\n' > "$WORK/big.qmd"
[[ "$(run "$WORK/big.qmd")" == 1 ]] && ok "'2,357' and '4.2' flagged" || bad "large/decimal should flag"

echo; echo "── PASS=$pass  FAIL=$fail ──"
[[ "$fail" -eq 0 ]]
