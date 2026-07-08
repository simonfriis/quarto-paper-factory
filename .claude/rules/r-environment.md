---
paths:
  - "**/*.R"
  - "**/*.Rmd"
  - "**/*.qmd"
  - "**/*.Rnw"
  - "**/*.Rproj"
  - "**/DESCRIPTION"
  - "**/NAMESPACE"
  - "**/renv.lock"
  - "**/renv/**"
---

## R environment and dependency management

### renv

This project uses `renv` for reproducible dependency management. If `renv`
is not yet initialized (no `renv.lock`), the SessionStart hook will
initialize it automatically with `renv::init(bare = TRUE)`.

- Use `renv::install("pkg")` to add packages, never bare `install.packages()`.
- After installing or removing packages, run `renv::snapshot()` and present
  the diff to `renv.lock` before committing. Explain what changed and why.
- Do not modify `renv.lock` by hand.
- Use `renv::status()` to diagnose dependency drift when something
  unexpectedly fails to load.
- The packages `languageserver` and `lintr` are development tooling installed
  into this renv by the SessionStart hook. They are not project dependencies.
  Do not add them to DESCRIPTION.

### Running R code

- Always assume the renv environment is active (the project `.Rprofile`
  handles activation).
- When running scripts, use `Rscript` from the project root so renv
  activates correctly.
- If a package fails to load, check `renv::status()` before attempting
  to install — the package may be recorded in the lockfile but not yet
  installed locally (`renv::restore()` fixes this).

### Project structure conventions

Organize files so that the dependency graph flows in one direction:

```
data/bronze/    → immutable raw + third-party inputs (gitignored)
data/silver/    → typed, validated, analysis-ready tables (reproducible from bronze)
data/gold/      → analytical-decision outputs (aggregates, features, final datasets)
munge/          → bronze → silver/gold cleaning scripts (numbered, run in sequence)
scripts/R/      → reusable functions + analysis scripts
manuscript/     → Quarto book (chapters read from silver/gold)
```

Cleaning scripts in `munge/` run in numbered sequence; reusable functions
in `scripts/R/` should not source each other circularly.
