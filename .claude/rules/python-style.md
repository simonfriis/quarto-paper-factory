---
paths:
  - "**/*.py"
  - "**/*.ipynb"
---

# Python & Databricks notebook style

Applies to all Python (`.py`) and notebook (`.ipynb`) files. Distilled from this project's
`STANDARD.md`. When a specific rule and a governing principle disagree, the principle wins.

Most sections pair the **chosen** style (`✓`) with the **closest tempting alternative**
(`✗`) — the near-miss Claude tends to reach for by default. Match the `✓`; the `✗` examples
are labelled with *why* they're tempting so you can recognise and avoid them.

## Governing principles (tie-breakers)

1. **Literate, linear, minimal.** Self-contained, top-to-bottom narratives with one obvious
   entry point over layered abstraction. YAGNI — build only on present need. Duplicate twice
   freely; abstract on the third use.
2. **Standard idioms over clever compliance.** If a rule forces nonstandard code, fix the
   rule. A construct that needs a walkthrough to defend has failed.
3. **Specs describe what *is*.** Present-tense, zero process memory — no "previously", "now",
   "the new approach", or branch names.
4. **Comments narrate; errors instruct; failures are loud.** `raise` with a message saying
   what to do next; never `try/except` to swallow an error you can't fix.
5. **No auto-formatter — alignment is notation.** Lint for correctness, never restructuring.

## Comments — short, atomic, near per-line

One short, **atomic** comment above nearly every meaningful line — one action each, the why
folded in. Never bundle two actions into one comment; never restate the line; skip only the
mechanically obvious.

✓ **Chosen** — one action per comment, the why on the line it explains:

```python
# Split the claimed messages into provider-sized batches.
batches = split_into_batches(claims, batch_size)
for batch_id, frame in batches:
    # Write each batch to scratch first.
    scratch_path = write_jsonl(frame, volumes.scratch, batch_id)
    # Atomic-rename into staging — dispatch/01 must never see a half-written file.
    final_path = atomic_rename(scratch_path, volumes.batch_inputs, batch_id)
```

✗ **Avoid** — too sparse (names-only), the most common default; the reader rebuilds intent:

```python
batches = split_into_batches(claims, batch_size)
for batch_id, frame in batches:
    scratch_path = write_jsonl(frame, volumes.scratch, batch_id)
    final_path = atomic_rename(scratch_path, volumes.batch_inputs, batch_id)
```

✗ **Avoid** — one comment bundling two actions into a sentence; harder to scan:

```python
# Write each batch to scratch, then atomic-rename it into staging.
scratch_path = write_jsonl(frame, volumes.scratch, batch_id)
final_path = atomic_rename(scratch_path, volumes.batch_inputs, batch_id)
```

## Module docstring — summary + `Usage:` + `Design notes:`

A summary line, a `Usage:` block (show the import before explaining it), then `Design notes:`
bullets — one fact per bullet, the "why it exists this way" facts code can't state.

✓ **Chosen** — scannable; the reason-for-being is a bullet, not buried prose:

```python
"""Single source of truth for names, paths, and pipeline constants.

Usage:

    from shared.config import tables, volumes, limits, defaults

Design notes:

- Names derive per deployment target — catalog/schema arrive via env vars from the bundle.
  That is why this is Python and not a static file.
- Attribute names mirror the DDL exactly, for grep-ability.
- All namespaces are frozen; nothing is mutable at runtime.
"""
```

✗ **Avoid** — the close runner-up: the "why" dissolved into a prose paragraph, no
`Usage:` / `Design notes:` scaffolding (this is Claude's instinctive default):

```python
"""Single source of truth for names, paths, and pipeline constants.

Four frozen namespaces; notebooks import what they need. Table and volume names are derived
per deployment target (catalog and schema come from the bundle via environment variables),
which is why this is Python and not a static file.
"""
```

## Function docstring — full Google-style

Every public function: summary, `Args:`, `Returns:`, `Raises:` — *even for "obvious"*
parameters. Classes get a one-liner. Uniformity is the point.

✓ **Chosen** — every function answers the same four questions in the same place:

```python
def conform(df, table_name):
    """Conform a frame to a table's DDL schema.

    Adds typed null columns for every missing target column, then casts to the exact schema.

    Args:
        df: Frame holding only the meaningful columns.
        table_name: Fully qualified target table name.

    Returns:
        DataFrame matching the target table's schema exactly.

    Raises:
        AnalysisException: If a populated column cannot be cast to the DDL type.
    """
```

✗ **Avoid** — the close runner-up: "lean Google" that drops `Args:`/`Returns:` when they
feel obvious. It reads fine in isolation, but "obvious enough to skip" is a per-function
judgement call that drifts — so we don't make it:

```python
def conform(df, table_name):
    """Conform a frame to a table's DDL schema.

    Adds typed null columns for every missing target column, then casts to the exact schema.

    Raises:
        AnalysisException: If a populated column cannot be cast to the DDL type.
    """
```

## Narrative cells & block comments — declarative lead + bold-lead bullets

One declarative lead sentence naming the step, then **bold-lead-in bullets** — the invariant
or failure rule as the bolded lead. Grow depth by adding bullets, not paragraphs.

✓ **Chosen** — the invariant is the first thing the eye lands on:

```text
## 3 · Claim: guard, then anti-join and persist

Claims the selected messages: inserts one row per message into `summarization_inputs`.

- **Claims are permanent** (ADR 001). The anti-join is the never-pay-twice guarantee.
- **The guard runs before any write.** A wrong claim is undone only by manual ledger surgery.
```

✗ **Avoid** — the close runner-up: a flowing prose paragraph (or unbolded bullets) that
buries the invariant mid-sentence:

```text
## 3 · Claim

This step inserts one row per selected message into `summarization_inputs`. Note that claims
are permanent, so the size guard runs before any write, and the run aborts above the
threshold unless allow_large_run is set.
```

## Layout — hand-aligned trailing comments (no formatter)

Hand-align trailing comments into columns; this is *why* no formatter runs.

✓ **Chosen** — reads as a two-column table (name | meaning):

```python
class Limits(BaseModel, frozen=True):
    large_run_threshold: int          # selections above this require allow_large_run
    token_budget_per_run: int         # projected input tokens above this abort the run
    max_requests_per_batch_file: int  # provider file limit
```

✗ **Avoid** — single space before `#` (what `ruff format` / black produce); the table
dissolves and the comment starts jitter line to line:

```python
class Limits(BaseModel, frozen=True):
    large_run_threshold: int  # selections above this require allow_large_run
    token_budget_per_run: int  # projected input tokens above this abort the run
    max_requests_per_batch_file: int  # provider file limit
```

Group related definitions with light `# --- region ---` dividers (max two or three per file;
more means it wants to split). Never banner boxes.

## Embedded SQL — clause-aligned + `transition:` caption

Clause-align the keywords; precede a state-changing statement with a caption naming the edge.

✓ **Chosen**:

```python
# transition: submitted → harvestable
spark.sql("""
    UPDATE summarization_batch_jobs
    SET    status       = 'harvestable',
           harvested_at = current_timestamp()
    WHERE  job_name = :job_name
      AND  status   = 'submitted'
""")
```

✗ **Avoid** — no caption, clauses packed together; the state-machine edge is implicit:

```python
spark.sql("UPDATE summarization_batch_jobs SET status='harvestable', "
          "harvested_at=current_timestamp() WHERE job_name=:job_name AND status='submitted'")
```

## Errors — `raise` with a next step; never swallow

✓ **Chosen** — the message names the count and the fix:

```python
if n_candidates > limits.large_run_threshold and not allow_large_run:
    raise RuntimeError(
        f"{n_candidates:,} candidates exceeds {limits.large_run_threshold:,}. "
        "Re-run with allow_large_run=true if this is intentional."
    )
```

✗ **Avoid** — swallowing an error you can't fix; an unexpected failure should kill the run:

```python
try:
    claims.write.mode("append").saveAsTable(INPUTS)
except Exception:
    pass
```

## Tooling

- **No formatter** (`ruff format` stays off) — document the reason in the linter config.
- Lint for **correctness only**: errors, unused, imports, bugbears, modernizers, docstring
  presence/shape. Disable restructuring rules.
- `make check` = lint + tests; work is not done until it passes.
