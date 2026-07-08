# Research Workflow: Exploration, Data, and Reproducibility

---

## 1. Dataset Versioning (Multi-Project Data)

**The pain point:** A shared dataset feeds multiple paper projects. Cleaning improvements should propagate, but each paper needs a stable, reproducible data input. Long-lived branches diverge silently and cause painful surprises.

**The resolution:** Shared datasets live in their own repository with tagged releases.

### The workflow

1. **Separate repo** for the shared dataset and its cleaning pipeline
2. **Tag stable releases:** `dataset-v1.0`, `dataset-v1.1`, etc.
3. Each paper project **pins to a specific tag** (documented in the project's README or data manifest)
4. When a fix is needed:
   - Branch from the relevant tag
   - Apply the fix
   - Tag the new release (`dataset-v1.0.1`)
   - Each downstream project decides if and when to adopt the updated tag

### Why tags, not long-lived branches

A tag says "this is a stable, citable artifact." A branch says "this is under active development." For data inputs to a paper, you want the former. Tags don't drift. Branches do.

### Within a single-project repo

If the dataset is project-specific (not shared), it still benefits from clear separation (medallion layout):
- `data/bronze/` — immutable original/third-party inputs, gitignored (provenance in `data/DATA_MANIFEST.md`)
- `data/silver/` — typed, validated, analysis-ready tables, reproducible from bronze
- `data/gold/` — analytical-decision outputs (aggregates, feature tables, final analysis datasets)
- Cleaning scripts in `munge/` (and `scripts/`) are production code and must work on main

---

## 2. Exploration Workflow

Research involves three layers, not two:

| Layer | What it is | Persistence |
|-------|-----------|-------------|
| **Production pipeline** | Code and manuscript that produce the paper. Must always work. Lives on main. | Permanent |
| **Exploration archive** | Self-contained records of investigative sessions. Each is a mini-project with its own files. | Permanent (but allowed to break) |
| **Working mess** | The actual state mid-exploration. Dozens of files, half dead ends. | Temporary (cleaned up before archival) |

### Starting an exploration

1. Create a branch: `explore/YYYY-MM-DD_short-description`
2. Create the session directory: `explorations/YYYY-MM-DD_short-description/`
3. All exploratory work — notebooks, intermediate outputs, scratch scripts, trial codebooks — lives in that session directory
4. Make atomic commits on the branch as you work (these are your detailed lab notes)

### Preserving intermediate artifacts

**The principle: the exploration directory is the record, not the git history of the branch.** Squash-merging destroys intermediate commit states. If an artifact — a rendered PDF, an interesting plot, a version of a table — is worth remembering, give it a descriptive name and keep it as a file. Do not rely on git history to preserve it.

**During exploration, use descriptive versioned filenames instead of overwriting a single output:**

```
# Bad — each version overwrites the last; only the final survives squashing
coefplot.pdf
results_table.tex

# Good — the intellectual trail is preserved as files
coefplot_v1_baseline.pdf
coefplot_v2_firm-fe.pdf
coefplot_v3_poisson.pdf
results_table_v1_ols.tex
results_table_v2_poisson.tex
```

This makes SUMMARY.md more useful — you can reference specific artifacts: "Switching to Poisson was motivated by the pattern visible in `coefplot_v2_firm-fe.pdf`."

**Claude Code discipline:** When rendering outputs during exploration, always use descriptive, versioned filenames. Never overwrite a previous output unless it is genuinely superseded and uninteresting.

### Concluding an exploration

1. Write `explorations/YYYY-MM-DD_short-description/SUMMARY.md` capturing:
   - What question motivated this session
   - What you tried
   - What you concluded
   - What (if anything) needs to change in the production pipeline
2. Squash-merge the branch to main with a single `explore:` commit message summarizing the session
3. The session directory with all artifacts arrives on main as one coherent commit

### If the exploration changes the production pipeline

Changes to the paper, scripts, or data pipeline motivated by an exploration happen in a **separate branch** off main — not inside the exploration branch. This keeps the production change clean and reviewable on its own terms. Reference the exploration session in the commit message:

```
analyze(models): switch to Poisson estimator per exploration 2025-04-03

See explorations/2025-04-03_count-model-comparison/SUMMARY.md
```

### Exploration directories are self-contained and ephemeral

- Notebooks and scripts include all code needed to run (no imports from `scripts/`)
- Outputs (plots, tables, intermediate data) are committed alongside code
- **Explorations will break over time** as upstream data and code evolve — this is expected
- The committed outputs and SUMMARY.md preserve the record; re-runnability is not guaranteed
- If you need to reconstruct what happened, git archaeology (checking out the commit) restores the full state

---

## 3. Notebook Output Discipline

**The tension:** Committing notebook outputs (plots, tables, printed results) makes them a useful record. But during active work, output diffs are enormous and obscure the real code changes.

**The resolution:** Notebooks have two phases.

| Phase | Outputs committed? | Rationale |
|-------|-------------------|-----------|
| **Active exploration** | No — clear outputs before committing | Keeps diffs readable while you iterate |
| **Archival** | Yes — commit with outputs as final record | Preserves the results at time of completion |

When you finish an exploration session and write the SUMMARY.md, that's the moment to run the notebook clean, confirm outputs, and commit with outputs included. This is the archival snapshot.

---

## 4. Data Governance

### What to commit

- Code (always)
- Documentation, codebooks, data manifests (always)
- Small, non-sensitive processed datasets (judgment call — generally < 50MB)
- Notebook outputs in archival phase (see §3)

### What to .gitignore

- Raw data files (especially large or sensitive) — document provenance in a manifest instead
- Credentials, API keys, tokens
- Compiled outputs that can be regenerated (`.aux`, `.log`, `.pdf` unless final)
- Environment-specific files (`.Rhistory`, `__pycache__`, `.DS_Store`)
- Intermediate data files that are reproducible from the pipeline

### Data manifest

For gitignored data, maintain a `data/DATA_MANIFEST.md`:

```markdown
# Data Manifest

| File | Source | Access | Size | Notes |
|------|--------|--------|------|-------|
| raw/survey_2024.csv | Qualtrics export | IRB protocol #1234 | 45MB | Download from [link] |
| raw/census_tract.shp | Census Bureau | Public | 200MB | TIGER/Line 2023 |
```

This ensures anyone (including future-you) can reconstruct the data directory even though the files aren't in the repo.

---

## 5. Environment Reproducibility

**The pain point:** The notebook broke not because the code changed but because a package updated. Git tracks code state but not environment state.

**The resolution:** Pin dependencies and commit the lockfile.

- **R:** Use `renv`. Commit `renv.lock`. Run `renv::snapshot()` when dependencies change.
- **Python:** Use `pip freeze > requirements.txt` or `poetry.lock` / `uv.lock`. Commit the lockfile.
- **Stata:** Document version and installed packages in the README.

When something stops working after a package update, `git diff renv.lock` (or equivalent) tells you exactly what changed.
