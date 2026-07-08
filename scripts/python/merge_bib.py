"""Deterministic bibliography merge for the pipeline (spec §5.4).

Usage:
    python3 scripts/python/merge_bib.py                       # merge the default sources
    python3 scripts/python/merge_bib.py --check a.bib b.bib   # dry-run: report, write nothing
    python3 scripts/python/merge_bib.py --out out.bib a.bib   # explicit output + sources

Merges the pipeline's staged .bib files into one references.bib, deterministically, so the
bibliography is built by a script rather than by three fragile LLM transcription hops. It:
  1. dedupes DOI-first (fallback: normalized title + year),
  2. HARD-ERRORS on citekey collisions (same @key used for two different works),
  3. strips `url` / `urldate` fields (the house bibliography style crashes on them),
  4. checks that every @key cited in manuscript/*.qmd resolves in the merged set.

Design notes:
- Default sources: codex_references.bib, argument_references.bib, literature/seed.bib
  (whichever exist). Default output: manuscript/references.bib.
- Output is normalized (`@type{key,\\n  field = {value},\\n ...}`) so re-runs are stable diffs.
- The parser is pragmatic (balanced braces, `{..}` / ".." / bareword values) — enough for the
  generated .bib files; it skips @string/@preamble/@comment.
- Exit 1 on a citekey collision or (with --check-citations) an unresolved citation.
"""

import glob
import re
import sys
from pathlib import Path

DEFAULT_SOURCES = ["codex_references.bib", "argument_references.bib", "literature/seed.bib"]
DEFAULT_OUT = "manuscript/references.bib"
DROP_FIELDS = {"url", "urldate"}  # the house bibliography style crashes on url fields


def split_top_level(text: str, sep: str) -> list[str]:
    """Split on `sep` only at brace/quote depth 0 (so commas inside values are kept)."""
    parts, depth, in_quote, start = [], 0, False, 0
    for i, ch in enumerate(text):
        if ch == '"' and depth == 0:
            in_quote = not in_quote
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
        elif ch == sep and depth == 0 and not in_quote:
            parts.append(text[start:i])
            start = i + 1
    parts.append(text[start:])
    return parts


def strip_wrap(value: str) -> str:
    """Strip one wrapping `{...}` or `"..."` and surrounding whitespace from a field value."""
    value = value.strip().rstrip(",").strip()
    if len(value) < 2:
        return value
    wrapped = (value[0] == "{" and value[-1] == "}") or (value[0] == '"' and value[-1] == '"')
    return value[1:-1].strip() if wrapped else value


def parse_bib(text: str) -> list[dict]:
    """Parse BibTeX into entries {type, key, fields}. Skips @string / @preamble / @comment."""
    entries: list[dict] = []
    i, n = 0, len(text)
    while i < n:
        at = text.find("@", i)
        if at == -1:
            break
        brace = text.find("{", at)
        if brace == -1:
            break
        etype = text[at + 1:brace].strip().lower()
        # Walk to the brace that closes this entry.
        depth, j = 0, brace
        while j < n:
            if text[j] == "{":
                depth += 1
            elif text[j] == "}":
                depth -= 1
                if depth == 0:
                    break
            j += 1
        body = text[brace + 1:j]
        i = j + 1
        if etype in ("string", "preamble", "comment"):
            continue
        parts = split_top_level(body, ",")
        key = parts[0].strip()
        fields: dict[str, str] = {}
        for part in parts[1:]:
            if "=" not in part:
                continue
            name, _, val = part.partition("=")
            name = name.strip().lower()
            if name:
                fields[name] = strip_wrap(val)
        if key:
            entries.append({"type": etype, "key": key, "fields": fields})
    return entries


def norm_doi(doi: str) -> str:
    """Normalize a DOI to a bare, lowercase form for matching."""
    d = doi.strip().lower()
    for prefix in ("https://doi.org/", "http://doi.org/", "doi:"):
        if d.startswith(prefix):
            d = d[len(prefix):]
    return d.strip()


def dedup_key(entry: dict) -> str:
    """The identity of a work: its DOI if present, else normalized title + year."""
    fields = entry["fields"]
    if fields.get("doi"):
        return "doi:" + norm_doi(fields["doi"])
    title = re.sub(r"[^a-z0-9]", "", fields.get("title", "").lower())
    return f"title:{title}|{fields.get('year', '').strip()}"


def emit(entry: dict) -> str:
    """Render one entry as normalized BibTeX, dropping url/urldate fields."""
    lines = [f"@{entry['type']}{{{entry['key']},"]
    for name, value in entry["fields"].items():
        if name in DROP_FIELDS:
            continue
        lines.append(f"  {name} = {{{value}}},")
    if lines[-1].endswith(","):
        lines[-1] = lines[-1][:-1]
    lines.append("}")
    return "\n".join(lines)


def cited_keys(qmd_glob: str = "manuscript/*.qmd") -> set[str]:
    """Collect every citation key referenced in the manuscript prose (@key, [@key], [-@key])."""
    keys: set[str] = set()
    pattern = re.compile(r"(?<![\w`])-?@([A-Za-z][\w:.-]+)")
    for path in glob.glob(qmd_glob):
        text = Path(path).read_text(encoding="utf-8")
        # Drop fenced code and inline code so emails/handles/code are not mistaken for cites.
        text = re.sub(r"```.*?```", " ", text, flags=re.DOTALL)
        text = re.sub(r"`[^`]*`", " ", text)
        keys.update(m.group(1).rstrip(".:-") for m in pattern.finditer(text))
    return keys


def merge(sources: list[str]) -> tuple[list[dict], list[str]]:
    """Merge source .bib files; return (deduped entries, error messages)."""
    errors: list[str] = []
    seen_work: dict[str, dict] = {}        # dedup_key -> kept entry
    key_to_work: dict[str, str] = {}       # citekey -> dedup_key (collision guard)
    merged: list[dict] = []
    for src in sources:
        path = Path(src)
        if not path.exists():
            continue
        for entry in parse_bib(path.read_text(encoding="utf-8")):
            work = dedup_key(entry)
            ckey = entry["key"]
            if ckey in key_to_work and key_to_work[ckey] != work:
                errors.append(
                    f"citekey collision: @{ckey} refers to two different works "
                    f"({key_to_work[ckey]} vs {work})"
                )
                continue
            key_to_work.setdefault(ckey, work)
            if work in seen_work:
                continue  # same work already kept (duplicate)
            seen_work[work] = entry
            merged.append(entry)
    return merged, errors


def main(argv: list[str]) -> int:
    """Merge sources into references.bib (or --check dry-run); return the exit code."""
    args = list(argv)
    check_only = "--check" in args
    check_cites = "--check-citations" in args
    args = [a for a in args if a not in ("--check", "--check-citations")]
    out = DEFAULT_OUT
    if "--out" in args:
        k = args.index("--out")
        out = args[k + 1]
        del args[k:k + 2]
    sources = args or DEFAULT_SOURCES

    merged, errors = merge(sources)

    if check_cites:
        have = {e["key"] for e in merged}
        missing = sorted(cited_keys() - have)
        errors.extend(f"cited but unresolved: @{k}" for k in missing)

    for msg in errors:
        print(f"merge_bib: {msg}", file=sys.stderr)
    if errors:
        return 1

    body = "\n\n".join(emit(e) for e in merged) + "\n" if merged else ""
    n_src = len([s for s in sources if Path(s).exists()])
    if check_only:
        print(f"merge_bib: {len(merged)} entries from {n_src} source(s); "
              "no collisions. (--check: nothing written)")
    else:
        Path(out).write_text(body, encoding="utf-8")
        print(f"merge_bib: wrote {len(merged)} entries to {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
