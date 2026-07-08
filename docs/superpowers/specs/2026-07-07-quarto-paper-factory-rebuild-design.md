# Quarto-Native Paper Factory — Rebuild & Integration Design

- **Date:** 2026-07-07
- **Status:** Draft for review
- **Repo (home of this work):** `claude_paper_factory` (GitHub origin `simonfriis/quarto-paper-factory`), branch `feat/quarto-native-rebuild`
- **Author:** Simon Friis (with Claude)

---

## 1. Context & excavated goal

Over several projects, a system for **agentic social-science research** has been built up and has drifted across many repos in different states of completeness. This effort consolidates the proven pieces into one clean, reusable, **Quarto-native "paper factory" template**, and brings the surrounding component repos up to date so the whole system works as a coherent whole.

The **surface request** was "import the paper factory into a new project." The **excavated goal** is broader:

> Rebuild the base template (`claude_paper_factory`) as the distilled, de-specialized, Quarto-native essence of the working `cc_moral_economy` pipeline; make it (1) speak the canonical house code/comment style, (2) drop in the florilegium paper + plot themes via a single switch, and (3) run a **two-stage literature search** — broad web/Deep-Research first, then a deeper Grove pass (semantic search + OpenAlex citation expansion) seeded from those reports. Along the way, bring each component repo (grove, claude-style-kit, quarto-florilegium, florilegium-plot-theme) up to date and mutually integrable. `wildchat-tbv` becomes the first project instantiated from the finished template, as the end-to-end validation.

### 1.1 State of the source repos (as surveyed 2026-07-07)

| Repo | Role | State |
|---|---|---|
| `cc_moral_economy` | working implementation | ⭐ Complete, Quarto-native paper factory. Two orchestration systems inside it: the **active prompt pipeline** (`run_prompts.sh` + `prompts/*.txt`) and a **dormant worker-critic agent scaffold** inherited from clo-author (`run_pipeline.sh` + `.claude/agents/` + `.claude/skills/`). Deeply specialized to the moral-economy project. Large uncommitted working tree. |
| `claude_paper_factory` | intended base template | ⚠️ Stale fork of `nwilmers/paper_factory`: pure LaTeX + Stata-first, **zero Quarto, zero local commits**. Quarto conversion was planned (uncommitted `WORKFLOW.md`) but never started. Origin already renamed `simonfriis/quarto-paper-factory`. **This is what we rebuild.** |
| `quarto-florilegium` | paper theme | ✅ Finished `florilegium-pdf` Quarto extension (v0.1.0, PDF/XeLaTeX). Private; installs via `gh` tarball. |
| `florilegium-plot-theme` | plot theme | ✅ Finished ggplot theme, but named `theme_ruling_pen()` (not `theme_florilegium()`), **not an R package** (sourced scripts), and carries a **verbatim copy of the Quarto extension** (sync risk). `cc_moral_economy` does **not** actually use it yet. |
| `grove` | lit-search engine | ✅ Mature (275 tests, ~71% recall eval). OpenAlex + Semantic Scholar + Crossref + Unpaywall + Google Books + Zotero; SPECTER/OpenAI/Voyage semantic search; forward/backward citation expansion; gap analysis; clustering. Best features on **unmerged `feat/bibtex-import`** branch; `.claude/` nearly empty (a promised `grove-research` skill does not exist). |
| `claude-style-kit` | house style | ✅ Newest, canonical style source (June 2026). Drop-in `.claude/rules/python-style.md` + `r-quarto-style.md` with adversarial ✓/✗ framing. **Not a git repo.** Conflicts with `cc_moral_economy`'s R rules (see §6). Prose is deliberately out of scope. |

### 1.2 Systems that must stay OUT

- **clo-author** (`clo-simon`, fork of `hugosantanna/clo-author`): a *separate* agentic-research scaffold. `cc_moral_economy`'s `.claude/` worker-critic architecture, most agents/skills, and all hooks were **ported from clo-author**. clo-author is its own living system (with its own upstream and its own in-progress Quarto/style-kit branches). We keep the systems separate: **the paper factory = the prompt pipeline; the clo-author-derived agent scaffold does not enter the template.**
- **`reflection-*` agents** (17 O*NET/scholar-lens agents): a *third* system, global at `~/.claude/agents/reflection/`, belonging to a `postdoc_jmp` reflection sprint. Entirely out of scope; untouched.

### 1.3 The key structural finding

The active `run_prompts.sh` pipeline **dispatches zero subagents and zero skills**. Every step is a self-contained prompt sent to a fresh `claude`/`codex` session; context flows only through files on disk. Therefore the boundary between "paper factory" and "clo-author scaffold" is clean and mechanical (see §5 manifest), and dropping the agent scaffold costs the pipeline nothing.

---

## 2. Goals & non-goals

**Goals**

1. A de-specialized, Quarto-native `quarto-paper-factory` template built from `cc_moral_economy`'s active prompt pipeline.
2. Canonical house code/comment style from `claude-style-kit`, reconciled with the one florilegium-driven table exception, plus the paper factory's prose/writing layer.
3. Florilegium paper + plot themes integrated as single-source-of-truth, single-toggle, and actually wired in (plot theme included).
4. A two-stage literature workflow: interactive Deep-Research + WebSearch breadth → Grove depth → verified literature map that grounds the pipeline.
5. Component repos brought up to date and mutually integrable.
6. `wildchat-tbv` instantiated from the template as end-to-end validation.

**Non-goals**

- Porting or reviving the clo-author worker-critic agent scaffold or the dormant `run_pipeline.sh`.
- Touching the global `reflection-*` agents or the `postdoc_jmp` project.
- Making `quarto-florilegium` public (kept private + tarball install for now; revisit later).
- Merging the paper factory and clo-author into one system (kept separate by explicit decision).

---

## 3. Locked decisions

| # | Decision | Choice |
|---|---|---|
| 1 | Template home | Rebuild `claude_paper_factory` in place (origin `quarto-paper-factory`); content replaced with Quarto-native DNA distilled from `cc_moral_economy`. |
| 2 | System boundary | Keep clo-author separate; its agent scaffold stays out. Mirror clo-author *patterns* (e.g. Makefile florilegium install) without importing its identity files. |
| 3 | Orchestration spine | The prompt pipeline (`run_prompts.sh` + `prompts/`). Precise in/out manifest in §5 (inventory-driven). |
| 4 | House style | `claude-style-kit` canonical for code + comment style; **one override**: keep `modelsummary`/`tinytable` tables (florilegium needs it); layer the factory's prose/derobotification/sociology conventions on top. |
| 5 | Florilegium | Install-on-setup (no vendored copy); expose `theme_florilegium()` and wire it into figures. (Author's judgment, delegated.) |
| 6 | Grove lit search | Interactive **pre-pipeline** literature phase producing a verified `literature_map.md` that grounds the run; grove invoked as an external CLI prerequisite. Grove depth stage optional/when-appropriate. |
| 7 | Spec scope | All five sub-projects (A–E), sequenced with stop-and-review gates. |
| 8 | wildchat-tbv | Instantiate from the finished template as the final end-to-end validation. |

---

## 4. Target repository structure

```
quarto-paper-factory/                 (claude_paper_factory, rebuilt)
├── run_prompts.sh                     # pipeline runner — generic; latent bugs fixed
├── prompts/                           # 16 de-specialized step prompt files
│   ├── step1a_deep_research.txt       #   (literature grounding parameterized)
│   ├── step1b_data_wrangle.txt        #   (PROJECT DATA STATE genericized)
│   ├── step1c_key_variables.txt
│   ├── step1d_viability_gate.txt
│   ├── step1e_descriptive_map.txt
│   ├── step2_claude_analyst.txt  step2_codex_analyst.txt
│   ├── step3_synthesis.txt
│   ├── step4_architect.txt  step4_architect_lenses.txt  step4_architect_review.txt
│   ├── step4_auditor.txt  step4_decider.txt  step4_executor.txt
│   ├── step4_ext1..7_*.txt
│   ├── step5_argument_research.txt  step5_data_audit.txt
│   ├── step6_methods_audit.txt
│   ├── step7_paper_writer.txt         #   (__AUTHOR__ placeholder)
│   ├── step8..15_*.txt                #   (derobotification preserved at 15)
│   └── litphase_*.txt                 #   NEW: two-stage lit phase prompts (§7)
├── .claude/
│   ├── rules/                         # kit-canonical style + writing layer (§6)
│   │   ├── r-quarto-style.md          #   from claude-style-kit (canonical)
│   │   ├── python-style.md            #   from claude-style-kit (canonical)
│   │   ├── content-standards.md       #   tables override → modelsummary/tinytable
│   │   ├── r-environment.md  research-workflow.md  git-conventions.md
│   │   ├── logging.md  workflow.md     #   workflow trimmed to §Codex-CLI + generic
│   │   ├── sociology-conventions.md   #   writing layer (kept)
│   │   └── quality.md                 #   thresholds kept as informative context
│   ├── references/
│   │   ├── domain-profile.md          #   BLANK parametric template
│   │   ├── terminology-discipline.md  #   BLANK parametric template
│   │   ├── journal-profiles.md        #   generic (kept as-is)
│   │   ├── prose-craft.md             #   kept; now wired into writing prompts
│   │   ├── abstract-examples.md       #   kept; step-14 path fixed
│   │   └── model-papers-style.json    #   kept
│   ├── hooks/                         # web-search allowlist inject/gate + compaction
│   │   ├── inject-web-search-allowlist.py  gate-web-fetch-allowlist.py
│   │   ├── pre-compact.py  post-compact-restore.py  web-search-allowlist.json
│   ├── settings.json                  # perms incl. Bash(grove:*), quarto, Rscript, uv
│   └── settings.local.json
│   #  NO agents/  NO skills/   ← clo-author scaffold intentionally excluded
├── manuscript/                        # Quarto book, florilegium format
│   ├── _quarto.yml                    #   format: florilegium-pdf (+ optional asq)
│   ├── index.qmd  01-…-07.qmd  08-appendix.qmd  references.qmd
│   ├── _setup.R                       #   theme_set(theme_florilegium())
│   ├── render.sh
│   ├── references.bib                 #   (no url fields — style constraint)
│   └── chicago-author-date.csl
├── R/
│   └── theme_florilegium.R            # canonical plot theme, wired in (§8)
├── data/{bronze,silver,gold}/         # empty medallion scaffold + .gitkeep
├── literature/                        # empty; filled by the lit phase
│   └── reports/                       #   drop-zone for pasted Deep Research reports
├── munge/                             # empty; project fills
├── Makefile                           # `setup` installs florilegium (+asq); `render`; `lint`; `check`
├── project_brief.md                   # parametric scaffold — the one file you fill
├── CLAUDE.md                          # generic conventions
└── README.md  STEPS.md                # generic docs (rewritten from LaTeX/Stata originals)
```

Note: the existing stale LaTeX/Stata contents of `claude_paper_factory` (`run_paper.sh`, `compile_paper.sh`, `stata_*.sh`, `resources/style/paper.sty`, `resources/bib/bibliography.bst`, `analysis_guide.md`, LaTeX prompts) are **removed** in the rebuild. `trace_viewer.py` and `scripts/cleanup_project_artifacts.py` are re-evaluated for reuse; `launch_agents.sh` is dropped (superseded by `run_prompts.sh`).

---

## 5. Component in/out manifest (inventory-driven)

Derived from tracing `run_prompts.sh` and every `prompts/*.txt` file in `cc_moral_economy`.

### 5.1 KEEP — distilled into the template

**Runner & pipeline**
- `run_prompts.sh` (generic; only project-specific line is an internal memo comment, removed)
- `prompts/` — 16 unique step prompt files (de-specialized per §9)
- `run_state/factory/` + `logs/factory/` (auto-created marker/log dirs)

**`.claude/hooks/` (all four — generic utilities, active in every session)**
- `inject-web-search-allowlist.py`, `gate-web-fetch-allowlist.py`, `web-search-allowlist.json`
- `pre-compact.py`, `post-compact-restore.py`

**`.claude/rules/` (house style + writing + workflow)**
- `content-standards.md` (with table override), `r-environment.md`, `research-workflow.md`, `git-conventions.md`, `logging.md`, `sociology-conventions.md`, `quality.md` (thresholds as context)
- `workflow.md` — trimmed to the generic + Codex-CLI-integration content (orchestrator/skill sections removed)
- **Replaced** by claude-style-kit: `r-style-general.md` + `r-style-notebooks.md` → `r-quarto-style.md`; add `python-style.md`
- `agents.md`, `revision.md` — reviewed; kept only if genuinely generic after stripping worker-critic/skill references, else dropped

**`.claude/references/`**
- `domain-profile.md`, `terminology-discipline.md` → **blanked to parametric templates**
- `journal-profiles.md`, `prose-craft.md`, `abstract-examples.md`, `model-papers-style.json` → kept (prose-craft now wired into writing steps 7/9/10/15)

**Structure**
- `manuscript/` Quarto book scaffold (`_quarto.yml`, chapter `.qmd`s, `_setup.R`, `render.sh`, `references.bib`, CSL)
- `data/{bronze,silver,gold}/` medallion layout, `munge/`, `literature/`, `scripts/`, `quality_reports/` (as empty scaffolds)
- `.claude/settings.json` + `settings.local.json` (perms; extended for grove)

### 5.2 DROP — clo-author's dormant scaffold

- `run_pipeline.sh`
- All 30 `.claude/agents/*.md` (worker-critic pairs, orchestrator, ext-*, viability-screener, decider, executor, data-auditor, prose-critic, referees, editor, verifier)
- All 12 `.claude/skills/*/SKILL.md`

Rationale: the active pipeline never invokes them (§1.3). The paper-factory-original agents (architect, decider, ext-*, etc.) are **redundant** with the corresponding `prompts/step4_*.txt` files, which already encode the same logic and are what the pipeline actually runs.

### 5.3 FIX — latent bugs found during inventory

1. `__FACTORY__` placeholder appears in `step7`, `step8`, `step14` but is never substituted by `fill_prompt()`. → Add to substitution map (resolve to the template root path) **or** remove references.
2. `__BASE_NAME__` placeholder in `step7`/`step8` never substituted. → Add to `fill_prompt()` (source from `project_brief.md` or a CLI arg) or remove.
3. `scripts/verify_numbers.py` referenced by `step7`/`step8` does not exist. → Either port a real number-verification helper or remove the invocation.
4. `step14_abstract.txt` reads `__FACTORY__/.claude/references/abstract-examples.md` → currently broken; fixed by (1).

---

## 6. House style integration (Sub-project B)

### 6.1 Reconciliation

| Dimension | Template adopts | Source |
|---|---|---|
| Pipe | native `\|>` | claude-style-kit |
| Namespacing | bare `library()` + bare calls; `pkg::` only for incidental one-offs | claude-style-kit |
| Throwaway lambda | `\(x)` | claude-style-kit |
| Grouping | `.by =` (both sources already agree) | both |
| **Tables** | **`modelsummary` + `tinytable`** (OVERRIDE — florilegium's `se-grouping.lua` needs `talltblr`) | cc_moral_economy |
| Comment density | near-per-line atomic comments | claude-style-kit |
| Lint gate | `lintr` + `ruff` via `make check` + PostToolUse lint (optional) | claude-style-kit |
| Prose / writing | sociology-conventions, prose-craft, terminology-discipline, derobotification (step 15) | cc_moral_economy (kit omits prose by design) |

### 6.2 Actions

- Copy `claude-style-kit/.claude/rules/{r-quarto-style,python-style}.md` into the template's `.claude/rules/`, keeping their `paths:` frontmatter.
- Edit the table section of `r-quarto-style.md` (and `content-standards.md`) so `modelsummary`/`tinytable` is the table stack, not `gt`, with a one-line note explaining the florilegium dependency.
- Retire `cc_moral_economy`'s `r-style-general.md` / `r-style-notebooks.md` (superseded).
- Keep the writing-layer rules/references; add explicit pointers to `prose-craft.md` in the writing prompts (steps 7, 9, 10, 15) so it is actually consumed (it was previously only referenced by the dormant agents).
- Wire the lint gate into the `Makefile` (`lint`, `check` targets).

---

## 7. Grove + two-stage literature workflow (Sub-project D)

### 7.1 Shape: an interactive pre-pipeline phase

A guided **literature phase runs before** the autonomous `run_prompts.sh` pipeline and produces the inputs the pipeline already expects (`literature/literature_map.md` + a seed `.bib`). This matches the existing architecture (step 1a already reads a pre-built `literature_map.md`).

```
STAGE 1 — BREADTH (interactive, human-in-the-loop)
  1. Factory emits tailored Deep Research prompts (ChatGPT + Claude) based on project_brief.md
  2. Human runs them; pastes reports into literature/reports/*.md
  3. Factory synthesizes reports + runs WebSearch (allowlist hooks active)
     → literature/research_brief.md  +  candidate seed set (DOIs / refs)

STAGE 2 — DEPTH (Grove; optional / when appropriate)
  4. grove import-bibtex / grove acquire --doi …           (seed from the synthesis)
  5. grove expand <ids>                                     (OpenAlex + S2 fwd+back citations)
  6. grove index && grove similar --tag seeds               (semantic neighbors)
  7. grove gaps --tag seeds --by coupling                   (corpus-coupling gaps)
  8. grove bibtex --tag seeds                               (export verified .bib)
     → literature/literature_map.md (OpenAlex-verified, tiered)  +  literature/seed.bib

  ↓ grounds step 1a onward, exactly as cc_moral_economy expects today.
```

### 7.2 Integration mechanics

- **Grove is an external CLI prerequisite**, not vendored. Documented in `CLAUDE.md`/`README.md`/prerequisites. Installed separately (`uv tool install` or a documented path); DB at `$GROVE_DB`.
- `.claude/settings.json` extended to allow `Bash(grove:*)` and/or `Bash(uv run grove:*)` without prompting.
- The literature phase is implemented as **prompt file(s) driven the same way as pipeline steps** (`prompts/litphase_*.txt`), not as a `.claude` skill (skills are the dropped scaffold layer). The interactive pause = the human runs Deep Research externally and drops files into `literature/reports/`; a subsequent prompt ingests them.
- Stage 2 is **optional**: papers that don't need the deep pass produce `literature_map.md` from Stage 1 alone.
- Env/keys grove may need (documented, not required for basic use): `OPENALEX_EMAIL`, optional `SEMANTIC_SCHOLAR_API_KEY`, `ANTHROPIC_API_KEY` (for `grove resolve`/`import` LLM validation), embedding backend keys if not using local SPECTER.

### 7.3 Deliverable artifacts

`literature/reports/` (pasted DR reports), `literature/research_brief.md` (Stage-1 synthesis), `literature/literature_map.md` (final grounding doc, tiered + OpenAlex-verified), `literature/seed.bib`.

---

## 8. Florilegium integration (Sub-project C)

### 8.1 Paper theme (Quarto extension)

- Installed via a `Makefile` `setup` target that runs `quarto add` against the `quarto-florilegium` repo (tarball via `gh` while private — mirroring clo-author's Makefile pattern). **No vendored copy** in the template; single source of truth = `quarto-florilegium`.
- `manuscript/_quarto.yml` declares `format: florilegium-pdf` (optional `asq-*` formats available). Font fallbacks (EB Garamond / Inter) documented for machines without Adobe fonts.

### 8.2 Plot theme (ggplot)

- Canonical `R/theme_florilegium.R` in the template, exposing **`theme_florilegium()`** (alias/rename of `theme_ruling_pen()`), palette `fl_pal`, and `fl_minus` label formatter.
- **Wired into the figure setup**: `manuscript/_setup.R` (and any `scripts/R/00_shared.R`) call `theme_set(theme_florilegium())`, replacing `cc_moral_economy`'s ad-hoc `theme_me`. This is a genuine upgrade — the factory did not previously use the house plot theme.
- Single toggle: one format key + one `theme_set()` call switch the whole visual identity; swapping to a plain default is a one-line change.
- Figure size convention reconciled (extension default 6.5×4in vs examples 5.2×3.2in) and documented once in `content-standards.md`.

### 8.3 Source repo housekeeping (part of E)

- Rename/alias in `florilegium-plot-theme`: expose `theme_florilegium()` publicly (keep `theme_ruling_pen()` as internal alias).
- Stop bundling the verbatim `_extensions/` copy inside `florilegium-plot-theme` (removes the manual sync risk); its demo `.qmd`s install the extension the same way the template does.

---

## 9. De-specialization plan

Every moral-economy coupling identified in the inventory becomes a parameter or a blank template:

| Target | Action |
|---|---|
| `project_brief.md` | Replace with a **parametric scaffold**: `## Research Question`, `## Theoretical Frame & Writing Constraints`, `## Data` (generic medallion instructions), `## Context`. The one file a new project fills. |
| `.claude/references/domain-profile.md` | Blank template: section headers + instruction comments only (field, journals, data sources, notation, seminal refs, referee concerns). |
| `.claude/references/terminology-discipline.md` | Blank template: generic three-tier structure + empty seed vocabulary table. |
| `prompts/step1a_deep_research.txt` | Parameterize grounding: "if `literature/literature_map.md` exists, read it first and build on it; else start from the Stage-1 synthesis." |
| `prompts/step1b_data_wrangle.txt`, `step1c_key_variables.txt` | Replace "PROJECT DATA STATE — READ FIRST" paragraphs with a generic instruction pointing at `project_brief.md`. |
| `prompts/step7_paper_writer.txt` | Replace hard-coded `author: Simon Friis` with `__AUTHOR__` (filled from `project_brief.md`). |
| `prompts/step4_architect_lenses.txt` | **No change** — the 5 lenses are already generic. |
| `.claude/references/journal-profiles.md` | **No change** — already generic. |
| `literature/`, `data/`, `munge/` | Clear to empty scaffolds (`.gitkeep`); project fills. |
| `CLAUDE.md` | Rewrite project-specific sections (title, data, "Current Project State", agent/skill counts) to generic; keep Core Principles, Getting Started, Folder Structure, Commands, Prerequisites, Conventions. Remove the "two pipelines" section's dormant half. |
| `run_prompts.sh` | Remove the internal memo comment; otherwise generic. |

---

## 10. Component housekeeping (Sub-project E)

| Repo | Action |
|---|---|
| `grove` | Merge `feat/bibtex-import` → `main` (contains bibtex import, `acquire`/`tag`, `expand`, `clusters`, `similar`, gap `--by`). Decide on experimental `feat/discovered-works-cache` (merge or park with a note). Optionally build the `grove-research` `.claude/skill` its CLAUDE.md promises. Confirm test suite green post-merge. |
| `claude-style-kit` | `git init` + initial commit (currently untracked). It is the canonical style source and should be versioned. |
| `quarto-florilegium` | Keep private + tarball install for now. Document the install path used by the template's `Makefile`. Revisit going public later. |
| `florilegium-plot-theme` | Expose `theme_florilegium()`; de-vendor the `_extensions/` copy. Optionally package as an installable R package (deferred unless low-cost). |

Cross-repo edits are done directly in each repo on a feature branch, committed atomically, and PR'd per that repo's conventions. Grove/style-kit/florilegium changes are **not** vendored into the template — the template depends on them as external, independently-versioned components.

---

## 11. Sequencing & milestones

Stop-and-review gate (⛔) after each milestone.

- **M0 — Spec approved.** (this document) ⛔
- **M1 — Template spine (A).** Rebuild `claude_paper_factory`: remove LaTeX/Stata content; port `run_prompts.sh` + `prompts/` (de-specialized, bugs fixed); port `.claude/` rules/references/hooks (no agents/skills); Quarto `manuscript/` scaffold; generic `CLAUDE.md`/`README.md`/`STEPS.md`; medallion/`munge`/`literature` scaffolds. Verifiable: `run_prompts.sh --help`/dry-run lists steps; a placeholder `manuscript` renders. ⛔
- **M2 — House style (B).** Drop in kit rules; apply table override; retire superseded R rules; wire prose-craft + lint gate. Verifiable: `make lint` runs; rules load. ⛔
- **M3 — Florilegium (C).** `Makefile setup` installs the extension; `theme_florilegium()` added and wired into `_setup.R`; sample figure + table render with the house identity. Verifiable: `make render` produces a florilegium PDF with a themed figure and an SE-grouped table. ⛔
- **M4 — Grove + two-stage lit search (D).** `litphase_*` prompts; `settings.json` grove perms; documented prereqs. Verifiable: dry-run the lit phase on a toy brief → `literature_map.md` + `seed.bib` produced (Stage 2 exercised against a live grove DB). ⛔
- **M5 — Component housekeeping (E).** grove branch merge; style-kit git init; florilegium rename/de-vendor. Verifiable: grove tests green on `main`; style-kit has commits; florilegium exposes `theme_florilegium()`. ⛔
- **M6 — Instantiate `wildchat-tbv`.** `git init`; install template; fill `project_brief.md`; run the lit phase; smoke-test the first pipeline steps end-to-end. Verifiable: a real `literature_map.md` and initial pipeline artifacts for the WildChat project. ⛔

Milestones map to sub-projects A→E→validation. B, C, D can be developed against the M1 spine and reviewed independently; E is cross-repo and can proceed in parallel once M1 stabilizes.

---

## 12. Validation & testing

- **Template smoke test:** `run_prompts.sh` dry-run enumerates steps; placeholder `manuscript/` renders to PDF via `make render`.
- **Style gate:** `make lint` (lintr + ruff) passes on the template's own R/Python.
- **Florilegium render:** a canonical figure (via `theme_florilegium()`) and a `modelsummary`/`tinytable` regression table (with `notes=`) render correctly (SE grouping active) in the florilegium PDF.
- **Lit phase dry-run:** toy `project_brief.md` → Stage-1 synthesis → Stage-2 grove seed/expand/similar/gaps → `literature_map.md` + `seed.bib`. Requires a reachable grove install + DB.
- **Grove regression:** `grove` test suite green after the `feat/bibtex-import` merge.
- **End-to-end (M6):** `wildchat-tbv` instantiated and driven through the literature phase and the first pipeline steps.

---

## 13. Risks & open questions

1. **Font availability.** Florilegium's Adobe fonts (Minion/Myriad Pro) are commercial. Mitigation: default the template to the documented free-font fallback (EB Garamond / Inter); make the Adobe fonts an opt-in override.
2. **Grove install friction.** Grove needs Python/`uv`, a DB path, and (for full features) API keys. Mitigation: document a minimal-config path (local SPECTER embeddings, OpenAlex polite pool, no keys) and treat Stage 2 as optional.
3. **`quarto-florilegium` privacy.** Tarball install via `gh` requires auth; CI or a fresh machine needs a token. Mitigation: document; revisit making it public.
4. **`agents.md` / `revision.md` / `quality.md` residue.** These rules describe the dropped worker-critic system. Mitigation: keep only after stripping scaffold-specific content, else drop; verify no prompt depends on them.
5. **Codex dependency.** Step 1a and step 2 use the `codex` CLI. Mitigation: preserve the existing `--skip-codex` / claude-only path; document Codex as optional.
6. **Two-pipeline lineage in docs.** `cc_moral_economy`'s `CLAUDE.md` documents both pipelines; the template must not reintroduce the dormant half. Mitigation: rewrite `CLAUDE.md` from scratch for the template.
7. **`wildchat-tbv` project definition.** The actual WildChat research question/data are not yet specified here. Mitigation: M6 begins by filling `project_brief.md`; out of scope for the template build itself.

---

## 14. Success criteria

- `claude_paper_factory` (branch `feat/quarto-native-rebuild`) contains a clean, de-specialized, Quarto-native prompt-pipeline paper factory with **no** clo-author agent scaffold.
- House style = claude-style-kit canonical + the single documented table override + the retained prose/writing layer; lint gate runs.
- Florilegium paper + plot themes install-on-setup, are single-source-of-truth, and are actually wired into rendered output via `theme_florilegium()`.
- The two-stage literature workflow produces a verified `literature_map.md` that grounds the pipeline, with grove as an external dependency and Stage 2 optional.
- grove, claude-style-kit, and the florilegium repos are versioned, up to date, and mutually integrable.
- `wildchat-tbv` is instantiated from the template and passes the end-to-end smoke test.
```
