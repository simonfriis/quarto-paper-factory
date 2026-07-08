# Quarto Paper Factory

A reusable, Quarto-native template for **agentic social-science research**. It drives a
16-step pipeline that takes a research question and data and produces a
submission-quality manuscript — a Quarto book — with the analysis, drafting, review,
and revision run as fresh Claude/Codex sessions coordinated by `run_prompts.sh`.

It is designed to plug into a **house toolchain**:

- **House code/comment style** (`claude-style-kit`) via always-on `.claude/rules/`.
- **Florilegium** paper + plot themes (installed on `make setup`) — *added in M3*.
- A **two-stage literature search**: web + ChatGPT/Claude Deep Research for breadth,
  then the **grove** CLI (semantic search + OpenAlex citation expansion) for depth —
  *added in M4*.

## Quick start

```bash
make setup                     # install the R + Python toolchain (once)
cp -r <this-template> my-paper && cd my-paper && git init   # instantiate a project
$EDITOR project_brief.md       # fill in the one source-of-truth file
# add raw data to data/bronze/, write munge/ cleaning scripts -> data/silver/
./run_prompts.sh --status      # see the pipeline
./run_prompts.sh               # run / resume
make render                    # render the manuscript book
```

See **`CLAUDE.md`** for how the pipeline, gates, house style, and literature workflow
fit together, and **`STEPS.md`** for the step-by-step deliverables.

## What makes it robust

The pipeline's checks are **mechanical, not model-judged**: the runner verifies each
step's deliverable exists (including fan-out counts) before marking it done, parses
gate verdicts from line 1 only, halts rather than polishing unresolved work, and aborts
on any unresolved prompt placeholder. Unit tests: `bash tests/test_runner.sh`.

## Lineage

The prompt-pipeline design descends from Nathan Wilmers's `paper_factory`; this template
is a Quarto-native reimplementation distilled from a working project, with a hardened
runner, house style, florilegium themes, and a grove-backed literature search. It is a
separate system from the `clo-author` research scaffold.
