# Salvage — naked-numeral lint (for M2, spec §5.4 / §6.3)

Salvaged from the deleted LaTeX-era `scripts/verify_numbers.py` before it was removed in M1a.
That script *diffed* prose numbers against Stata logs (wrong tool for a dynamic Quarto doc).
The M2 lint **inverts** it: flag any numeric literal in `.qmd` **prose** (outside code chunks
and outside inline `` `r … ` `` spans) that is not on the allowlist — enforcing the §6.3
inline-number mandate so prose↔analysis drift is impossible by construction.

## Reusable number-detection regex

```python
# Matches integers, decimals, percentages, negatives, thousands-separators:
#   0.037  -0.067  13.8  48,539  2,600  0.435%
NUM = re.compile(r'-?\d[\d,]*\.?\d*%?')
```

## Reusable allowlist / skip rules (do NOT flag these)

- **Years:** `^(19|20)\d{2}$` (unless they carry a decimal).
- **Small enumerators / footnote markers:** integer value in `1..20` with no decimal point.
- **Zero.**
- Consider additionally allowlisting: IRB/dataset IDs, figure/table/section numbers in
  cross-references (`@fig-`, `@tbl-`, `#sec-`), and spelled-or-round rhetorical numbers.

## M2 lint logic (sketch)

1. Strip fenced code chunks (```` ```{...} ```` … ```` ``` ````) and inline `` `r …` `` spans
   from each `.qmd` — those are computed, not prose.
2. Run `NUM` over what remains (the prose).
3. Any match not on the allowlist → **fail the build**, printing file:line + context
   (±40 chars, as the original did) so the author converts it to a `` `r stats$…$lab` `` lookup.

## Also salvaged

`scripts/cleanup_project_artifacts.py` targeted LaTeX/Stata intermediates. For Quarto the
artifacts to prune are different (`.quarto/`, `_book/`, `_freeze/`, `_objects/`, `*_files/`) —
rebuild the cleanup helper against those rather than porting the old globs.
