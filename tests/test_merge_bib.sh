#!/usr/bin/env bash
# Tests for scripts/python/merge_bib.py — the deterministic bibliography merge (spec §5.4).

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$HERE")"
MERGE="$ROOT/scripts/python/merge_bib.py"

pass=0; fail=0
ok()  { echo "  ok  — $1"; pass=$((pass + 1)); }
bad() { echo "  FAIL — $1"; fail=$((fail + 1)); }
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
cd "$WORK" || exit 1

cat > a.bib <<'EOF'
@article{smith2020,
  title = {A Study},
  author = {Smith, J.},
  year = {2020},
  journal = {J. Things},
  doi = {10.1/abc},
  url = {https://example.com/x}
}
EOF
cat > b.bib <<'EOF'
@article{smith2020dup, title = {A Study, Reprinted}, year = {2021}, doi = {https://doi.org/10.1/abc}}
@article{jones2019, title = {Another}, year = {2019}}
EOF

# 1. DOI dedup: smith2020 + smith2020dup share DOI -> 1 work; + jones2019 = 2
out="$(python3 "$MERGE" --check a.bib b.bib 2>&1)"
echo "$out" | grep -q "2 entries" && ok "DOI dedup (3 raw -> 2 works)" || bad "expected 2 merged ($out)"

# 2. url stripped; entry emitted
python3 "$MERGE" --out out.bib a.bib b.bib >/dev/null 2>&1
grep -q 'url' out.bib && bad "url field must be stripped" || ok "url field stripped from output"
grep -q '@article{smith2020,' out.bib && ok "entry emitted normalized" || bad "smith2020 should be emitted"

# 3. citekey collision (same @key, different works) -> hard error
printf '@article{dup, title={One}, year={2000}, doi={10.1/one}}\n' > c.bib
printf '@article{dup, title={Two}, year={2001}, doi={10.1/two}}\n' > d.bib
python3 "$MERGE" --check c.bib d.bib >/dev/null 2>&1 && bad "collision should exit 1" || ok "citekey collision hard-errors"

# 4. dedup by normalized title+year when no DOI
printf '@book{a1, title={Same Title}, year={1999}}\n' > e.bib
printf '@book{a2, title={Same  Title!}, year={1999}}\n' > f.bib
out="$(python3 "$MERGE" --check e.bib f.bib 2>&1)"
echo "$out" | grep -q "1 entries" && ok "title+year dedup (no DOI)" || bad "expected 1 entry ($out)"

# 5. citation resolve check against manuscript prose
mkdir -p manuscript
printf '# H\n\nAs @jones2019 shows [@missing2000].\n' > manuscript/ch.qmd
python3 "$MERGE" --out out.bib --check-citations a.bib b.bib >/dev/null 2>&1 \
  && bad "unresolved @missing2000 should exit 1" || ok "unresolved citation flagged"

echo; echo "── PASS=$pass  FAIL=$fail ──"
[[ "$fail" -eq 0 ]]
