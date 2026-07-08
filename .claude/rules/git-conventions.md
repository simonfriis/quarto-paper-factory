# Git Conventions for Empirical Social Science Research

---

## 1. Commit Messages: Research Conventional Commits

Use structured prefixes that reflect research workflows, not software development.

### Prefixes

| Prefix | Use For |
|--------|---------|
| `explore:` | Exploratory analysis sessions |
| `clean:` | Data pipeline and preparation |
| `analyze:` | Formal modeling, estimation, inference |
| `viz:` | Figures and tables |
| `draft:` | Manuscript prose |
| `revise:` | Reviewer-driven changes (R&R cycle) |
| `fix:` | Bug fixes in code or data |
| `refactor:` | Code restructuring (no output change) |
| `config:` | Environment, dependencies, build |
| `data:` | New data sources or acquisitions |
| `docs:` | READMEs, codebooks, documentation |

### Scope

Use parenthetical scope to reference the component:

```
clean(survey): standardize income coding across waves
analyze(models): add robustness check dropping top 1%
explore(qual-coding): test codebook v3 against subsample
viz(main-results): coefficient plot with confidence intervals
```

### Commit Body

For substantive commits, the body should answer: **what changed, why, and what it means for the paper.**

```
analyze(models): add firm fixed effects to baseline spec

Reviewer suggested unobserved firm heterogeneity may drive results.
Adding firm FE reduces coefficient on treatment from 0.34 to 0.28
but remains significant at 5%. Strengthens robustness story.
```

### Commit Bodies and Squash Merges

On exploration branches, commit bodies are useful working notes — include reasoning freely. But **squash merges collapse branch history into one commit on main**, so those bodies become invisible unless you check the branch or tag.

The rule: **any intellectual decision worth preserving must also go in SUMMARY.md before the squash merge.** Commit bodies are your notes while working; SUMMARY.md is the durable record. The squash commit on main should reference where the reasoning lives:

```
explore(predictive-validity): predictive validity analysis and merged results notebook

See explorations/2026-04-13_predictive_validity/ for all artifacts.
See explorations/2026-04-10_main_results_1/SUMMARY.md for specification decisions.
Tagged: jackie-main-results-pv-2026-04-14
```

---

## 2. Main Branch Discipline

**Main is the clean research narrative.** The git log on main should read like a table of contents of substantive decisions, not a play-by-play of every keystroke.

### What belongs on main

- Production pipeline code that works end-to-end
- The current manuscript
- Completed exploration session directories (squash-merged; see `research-workflow.md`)
- Substantive analytical decisions

### What does NOT belong on main (as individual commits)

- Work-in-progress atomic commits from exploratory sessions
- Half-finished analyses
- "trying something" commits

---

## 3. Tags as Research Milestones

Use annotated git tags to mark key moments in the paper's lifecycle:

```bash
git tag -a submission-v1 -m "Initial submission to ASQ, 2025-04-01"
git tag -a r1-received -m "First round reviews received, 2025-06-15"
git tag -a resubmit-v2 -m "R&R resubmission, 2025-08-20"
git tag -a accepted -m "Conditionally accepted, 2025-10-01"
```

This creates a navigable history of the **paper's** lifecycle, separate from the code's commit history. You can always check out a tag to see the exact state of everything at that moment.

### Dataset version tags (for shared data repos)

Tag stable dataset releases: `dataset-v1.0`, `dataset-v1.1`. Paper projects pin to a specific tag. See `research-workflow.md` §1 for the full dataset versioning workflow.

---

## 4. Output Provenance

**The pain point:** Your paper has Table 3. A reviewer says the numbers look wrong six months later. Which version of the code produced it?

**The resolution:** Analysis scripts should stamp outputs with the current git hash.

In R:
```r
git_hash <- system("git rev-parse --short HEAD", intern = TRUE)
cat(sprintf("# Produced by commit: %s\n", git_hash), file = "output_manifest.txt", append = TRUE)
```

In Python:
```python
import subprocess
git_hash = subprocess.check_output(["git", "rev-parse", "--short", "HEAD"]).strip().decode()
```

This is lightweight — a few lines at the end of your analysis script. When something looks wrong months later, you know exactly which commit to check out.
