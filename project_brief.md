# Project Brief

The single source of truth the pipeline reads. `run_prompts.sh` extracts the
research question (from `## Research Question`) and the author (from `## Author`)
and substitutes them into the step prompts. Fill in every section below before
running the pipeline.

## Research Question

<!-- One or two paragraphs. State the question, the core prediction, and why it
     matters. This text is injected into nearly every step prompt, so make it
     precise and self-contained. Replace this comment. -->

## Author

<!-- The manuscript author line, e.g.:  Jane Q. Researcher -->

## Theoretical Frame & Writing Constraints

<!-- The conceptual frame the paper argues from; target journal / discipline;
     target length; and any writing constraints (e.g., a required opening sentence).
     Fill in .claude/references/domain-profile.md with the same detail. -->

## Data

<!-- What data you have and where. The pipeline expects a medallion layout:
       data/bronze/   raw, untouched  (read-only; never committed)
       data/silver/   cleaned, analysis-ready (.parquet / .rds)
       data/gold/     analytical outputs
     Point the munge/ scripts at your raw sources, then describe the key
     variables and how they are constructed. -->

## Context

<!-- Anything else the agents should know: institutional background, prior work,
     constraints, IRB / ethics approvals, sample details. -->
