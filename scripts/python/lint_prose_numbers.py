"""Naked-numeral lint for Quarto manuscript prose (house rule, spec §6.3).

Usage:
    python3 scripts/python/lint_prose_numbers.py                 # defaults to manuscript/*.qmd
    python3 scripts/python/lint_prose_numbers.py path/to/*.qmd   # explicit files

Fails (exit 1) when a statistical number is typed directly into manuscript prose instead of
being computed inline as `r stats$...$lab`. Enforcing this makes prose numbers impossible to
diverge from the analysis — the number in the rendered sentence IS the computed value. It
replaces the old LaTeX prose-vs-log diff (verify_numbers.py) with prevention.

Design notes:
- Scans PROSE only. Exempt: fenced code chunks, inline `...` spans (including inline R),
  the YAML front matter, HTML comments, and math ($...$ / $$...$$).
- Allowlist: years (1900-2099), zero, and small whole-number enumerators / footnote markers
  (integers 1-20 with no decimal and no percent). Anything with a decimal, a thousands
  separator, a percent sign, or magnitude > 20 is flagged.
- A hardcoded result inside math is a known blind spot (math is notation); verify by eye.
- Deterministic and stdlib-only, so it runs as a mechanical gate in `make check` and the runner.
"""

import glob
import re
import sys
from pathlib import Path

# A numeric literal: integers, decimals, thousands-separated, percentages, negatives.
NUM = re.compile(r"-?\d[\d,]*\.?\d*%?")
# Spans stripped from a prose line before scanning (order matters: display math first).
DISPLAY_MATH_INLINE = re.compile(r"\$\$[^$]*\$\$")
INLINE_MATH = re.compile(r"\$[^$\n]*\$")
INLINE_CODE = re.compile(r"`[^`]*`")
# Years read as prose, not statistics.
YEAR = re.compile(r"^(19|20)\d{2}$")


def is_allowed(token: str) -> bool:
    """Return True if a numeric token is exempt from the mandate (year, zero, small enumerator)."""
    # Years like 1998 / 2026 are legitimate in prose.
    if YEAR.match(token):
        return True
    clean = token.replace(",", "").rstrip("%")
    try:
        value = float(clean)
    except ValueError:
        return True  # a stray hyphen or malformed match — not a real number
    # Zero carries no statistical content.
    if value == 0:
        return True
    # Small whole-number enumerators and footnote markers (no decimal, no percent) pass.
    has_decimal = "." in token
    has_percent = token.endswith("%")
    if not has_decimal and not has_percent and value == int(value) and 1 <= value <= 20:
        return True
    return False


def prose_violations(path: Path) -> list[tuple[int, str, str]]:
    """Return (line_no, token, context) for every naked numeral in one .qmd's prose."""
    violations: list[tuple[int, str, str]] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    in_yaml = in_fence = in_comment = in_math = False
    for line_no, raw in enumerate(lines, start=1):
        line = raw
        # YAML front matter: a leading '---' opens it, the next '---' closes it.
        if line_no == 1 and line.strip() == "---":
            in_yaml = True
            continue
        if in_yaml:
            if line.strip() == "---":
                in_yaml = False
            continue
        # Fenced code block: any line starting with ``` toggles in/out.
        if re.match(r"^\s*```", line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        # Display-math block on its own line ($$ ... $$ spanning multiple lines).
        if line.strip() == "$$":
            in_math = not in_math
            continue
        if in_math:
            continue
        # Continue a multi-line HTML comment.
        if in_comment:
            if "-->" in line:
                line = line.split("-->", 1)[1]
                in_comment = False
            else:
                continue
        # Strip same-line HTML comments; enter a multi-line comment if left unclosed.
        while "<!--" in line:
            before, _, rest = line.partition("<!--")
            if "-->" in rest:
                line = before + rest.split("-->", 1)[1]
            else:
                line = before
                in_comment = True
                break
        # Strip math and code spans so their numbers are not read as prose.
        line = DISPLAY_MATH_INLINE.sub(" ", line)
        line = INLINE_MATH.sub(" ", line)
        line = INLINE_CODE.sub(" ", line)
        # Flag any surviving numeric literal that is not on the allowlist.
        for match in NUM.finditer(line):
            # Strip trailing sentence punctuation the greedy match swallows (e.g. "3." -> "3").
            token = match.group().rstrip(",.")
            if not re.search(r"\d", token):
                continue
            if is_allowed(token):
                continue
            start, end = max(0, match.start() - 30), min(len(line), match.end() + 30)
            violations.append((line_no, token, line[start:end].strip()))
    return violations


def main(argv: list[str]) -> int:
    """Lint the given .qmd files (default manuscript/*.qmd); return the process exit code."""
    patterns = argv or ["manuscript/*.qmd"]
    files = sorted({Path(p) for pat in patterns for p in glob.glob(pat)})
    if not files:
        print(f"lint_prose_numbers: no files matched {patterns}", file=sys.stderr)
        return 0
    total = 0
    for path in files:
        for line_no, token, context in prose_violations(path):
            total += 1
            print(f"{path}:{line_no}: naked numeral '{token}' in prose  →  …{context}…")
    if total:
        print(
            f"\n{total} naked numeral(s) in prose. Every statistical number must be an inline "
            "`r stats$...$lab` lookup (spec §6.3). Allowlist: years, IDs, footnote markers, "
            "enumerators 1-20.",
            file=sys.stderr,
        )
        return 1
    print(f"lint_prose_numbers: {len(files)} file(s) clean — no naked numerals in prose.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
