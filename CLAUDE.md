# Quarto Paper Factory

A Quarto-native "paper factory": an autonomous, prompt-driven pipeline that turns a
research question + data into a submission-quality social-science manuscript. Each
step runs as a fresh Claude/Codex session; context flows only through files on disk.

## Core principles

1. **Single source of truth for the paper** — the Quarto book under `manuscript/`.
   Numbers, tables, and figures are computed at render time, never transcribed.
2. **Mechanical gates over model self-assessment** — step completion, gate verdicts,
   and (from M2) prose numbers and the bibliography are enforced by the *runner and
   scripts*, not by a model judging its own work. See `run_prompts.sh` (`step_check`,
   `kill_triggered`/`reopen_triggered`, the `fill_prompt` placeholder guard).
3. **Plan first, verify after** — plan a step before running it; confirm its
   deliverable exists before moving on (the runner will not mark a step done
   otherwise).
4. **House style is loaded, not remembered** — the always-on rules in `.claude/rules/`
   govern R/Quarto code, tables/figures, and writing. Follow them.
5. **Data hygiene** — medallion layout (`data/bronze` raw & read-only → `data/silver`
   cleaned → `data/gold` outputs). Never commit raw or large data.
6. **Git discipline** — atomic, conventional commits (`.claude/rules/git-conventions.md`).

## The pipeline

`run_prompts.sh` drives 16 steps (some fan out) from `prompts/step*.txt`. Run:

```bash
./run_prompts.sh --status          # show step status
./run_prompts.sh --dry-run --step 1a   # print a filled prompt, no model call
./run_prompts.sh                   # run / resume (pauses between steps)
./run_prompts.sh --auto --parallel # unattended, fan-outs concurrent
./run_prompts.sh --skip-codex      # route codex steps to Claude
```

See `STEPS.md` for the step list and each step's deliverable. Two hard gates: the
**viability gate** (Step 1d, `VERDICT: KILL` on line 1 halts the run) and the
**final-review reopen loop** (Step 11; a `VERDICT: REOPEN_STEP10*` line loops back to
Step 10 up to 3×, then halts for human review rather than polishing unresolved work).

## Two-stage literature search (wired in M4)

Before the pipeline runs, a literature phase produces `literature/literature_map.md`
(which Step 1a builds on):

1. **Breadth** — WebSearch plus human-provided ChatGPT / Claude Deep Research reports
   (dropped into `literature/reports/`), synthesized into a research brief + seed DOIs.
2. **Depth** — the external `grove` CLI seeds from those DOIs, expands the citation
   graph (OpenAlex forward/backward), runs semantic + gap search, and exports a
   verified `seed.bib`. Grove is a separate installed dependency; the depth pass is
   optional. Use a project-scoped tag (`<project>_seed`) to avoid blending corpora.

## House style (essentials)

- Code/notebooks: `.claude/rules/r-quarto-style.md`, `python-style.md` (native `|>`,
  bare `library()`, `\(x)`, near-per-line atomic comments; lint via `make lint`).
- Tables: `modelsummary` + `tinytable` (the florilegium format is built for it).
  Figures: ggplot, captions in the chunk (never inside the plot).
- **Numbers-in-prose mandate (M2):** every statistical number in manuscript prose is
  an inline `` `r stats$...$lab` `` lookup from a live results object — no naked
  numeric literals (allowlist: years, IDs, footnote/enumeration markers). A lint
  enforces it. This is what makes prose↔analysis divergence impossible.
- Writing: `.claude/rules/sociology-conventions.md`, `.claude/references/prose-craft.md`;
  Step 15 strips AI-tells (derobotification).

## Chapter setup-chunk pattern

Manuscript chapters that run R begin with:

```r
#| label: setup-<chapter>
#| include: false
source(here::here("manuscript/_setup.R"))
```

`manuscript/_setup.R` is the shared render engine (packages, theme, table backend).

## Folder structure

```
run_prompts.sh   the pipeline runner              prompts/     16-step prompt files
.claude/         rules · references · hooks · settings.json
manuscript/      Quarto book (_quarto.yml, chapters, _setup.R, render.sh, references.bib)
R/               shared R (theme_florilegium.R — added M3)
scripts/R,python analysis code (project fills)    munge/       bronze→silver cleaning
data/{bronze,silver,gold}   medallion data        literature/  lit-phase inputs + map
quality_reports/ plans + logs                     tests/       runner/gate unit tests
project_brief.md the one file you fill            Makefile     setup · render · lint · check
```

## Prerequisites

`claude` CLI (and optionally `codex`); `quarto` ≥ 1.5; **R ≥ 4.6** (the analysis +
render toolchain is pinned in `renv.lock`; `make setup` runs `renv::restore()`);
`uv`/`uvx` for `ruff`; `gh` (for the M3 extension install); `grove` + `OPENALEX_EMAIL`
for the M4 depth search. Run `make setup` once after cloning.

## Getting started

1. `make setup` — `renv::restore()` the pinned R toolchain (and, from M3, install the Quarto extensions).
2. Fill `project_brief.md` and `.claude/references/domain-profile.md`.
3. Put raw data in `data/bronze/`, write `munge/` cleaning scripts, build `data/silver/`.
4. Run the literature phase, then `./run_prompts.sh`.
