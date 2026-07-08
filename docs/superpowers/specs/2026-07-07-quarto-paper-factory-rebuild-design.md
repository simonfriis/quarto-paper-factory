# Quarto-Native Paper Factory — Rebuild & Integration Design

- **Date:** 2026-07-07
- **Status:** Draft for review (rev. 3 — rev. 2 folded in the Fable Oracle review [§5.4/§7.4 hardening, corrections C1–C16]; rev. 3 replaces the ported `verify_numbers.py` diff with the §6.3 inline-number mandate + naked-numeral lint)
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
| `grove` | lit-search engine | ✅ Mature (275 tests, ~71% recall eval). OpenAlex + Semantic Scholar + Crossref + Unpaywall + Google Books + Zotero; SPECTER/OpenAI/Voyage semantic search; forward/backward citation expansion; gap analysis; clustering. Best features on **unmerged `feat/bibtex-import`** branch (grove is currently checked out there); a `grove-research` skill **already exists** at `.claude/skills/grove-research/SKILL.md`. |
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
7. **Mechanical over model-judged checks:** the pipeline's gates (step completion, numbers, bibliography, verdicts) are enforced by the *runner and scripts*, not delegated to fresh LLM sessions that can rationalize their own failures (§5.4).

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
| 9 | Instantiation & checks | Template is **copied wholesale** into a new project dir, so `__FACTORY__` ≡ `__PROJECT_PATH__` and is dropped. Pipeline gates are runner/script-enforced, not model-judged (§5.4). |

---

## 4. Target repository structure

```
quarto-paper-factory/                 (claude_paper_factory, rebuilt)
├── run_prompts.sh                     # pipeline runner — generic; latent bugs fixed
├── prompts/                           # 33 files across the 16-step pipeline (de-specialized)
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
│   └── theme_florilegium.R            # plot theme (vendored from upstream), wired in (§8)
├── scripts/R/                         # analysis scripts + output/ logs (project fills)
├── quality_reports/                   # plans, session logs (project fills)
├── data/{bronze,silver,gold}/         # empty medallion scaffold + .gitkeep
├── literature/                        # empty; filled by the lit phase
│   └── reports/                       #   drop-zone for pasted Deep Research reports
├── munge/                             # empty; project fills
├── renv.lock  renv/                   # R dependency lockfile (restored at `make setup`)
├── pyproject.toml                     # Python deps (uv)
├── Makefile                           # `setup` installs florilegium + R/Py deps; `render`; `lint`; `check`
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
- `content-standards.md` (with table override), `research-workflow.md`, `git-conventions.md`, `logging.md`, `sociology-conventions.md`
- `r-environment.md` — kept, but **strip the phantom "SessionStart hook will initialize renv automatically" line** (no such hook exists — review C9); replace with an explicit `make setup` renv-restore instruction
- `workflow.md` — trimmed to the generic + Codex-CLI-integration content (orchestrator/skill sections removed)
- **Replaced** by claude-style-kit: `r-style-general.md` + `r-style-notebooks.md` → `r-quarto-style.md`; add `python-style.md`. **Port the delta**: the retired `r-style-general.md` carries `withr::with_seed()` (never bare `set.seed()`) — the kit has no seed guidance, so add it to the override section (review C12).
- **DROP** `quality.md` — it is 100% worker-critic scaffold content (score aggregation keyed to `*-critic` agents, the ≥95 gate); "keeping as context" would reinject the dropped scaffold's identity into every session (review C8). Any genuinely useful threshold moves into `research-workflow.md`.
- **DROP** `agents.md`, `revision.md` — describe the excluded worker-critic/skill system; the prompt pipeline does not use them.

**`.claude/references/`**
- `domain-profile.md`, `terminology-discipline.md` → **blanked to parametric templates**
- `journal-profiles.md`, `prose-craft.md`, `abstract-examples.md`, `model-papers-style.json` → kept (prose-craft now wired into writing steps 7/9/10/15)
- **DROP** `table-conventions.md` (referenced by nothing — review C13) and the empty root `templates/` dir.

**Structure**
- `manuscript/` Quarto book scaffold (`_quarto.yml`, chapter `.qmd`s, `_setup.R`, `render.sh`, `references.bib`, CSL)
- `data/{bronze,silver,gold}/` medallion layout, `munge/`, `literature/`, `scripts/`, `quality_reports/` (as empty scaffolds)
- `.claude/settings.json` + `settings.local.json` (perms; extended for grove)

### 5.2 DROP — clo-author's dormant scaffold

- `run_pipeline.sh`
- All 30 `.claude/agents/*.md` (worker-critic pairs, orchestrator, ext-*, viability-screener, decider, executor, data-auditor, prose-critic, referees, editor, verifier)
- All 12 `.claude/skills/*/SKILL.md`

Rationale: the active pipeline never invokes them (§1.3). The paper-factory-original agents (architect, decider, ext-*, etc.) are **redundant** with the corresponding `prompts/step4_*.txt` files, which already encode the same logic and are what the pipeline actually runs.

### 5.3 FIX — LaTeX-era vestige cluster (corrected per Oracle review, C1/C4)

The review corrected a false premise: **`scripts/verify_numbers.py` DOES exist** — in the stale `claude_paper_factory` base being rebuilt — where it is LaTeX/Stata-specific (expects `{base}_paper.tex`, Stata `.log` globs, `.tex` tables). It is the pipeline's **only mechanical number-verification tool**, and §4's "remove stale content" would delete it. The three "independent bugs" are one coherent vestige cluster driven by that script's placeholders. Corrected actions:

1. **Do NOT port `verify_numbers.py`'s approach.** It was a post-hoc diff of typed `.tex` numbers against Stata logs — the wrong tool for a dynamic Quarto document. In a Quarto-native factory every statistical number is an inline `r` lookup from a live results object (§6.3), so prose↔analysis divergence is *structurally impossible*; the residual mechanical gate is a naked-numeral **lint** (§5.4 must-do 3), not a diff. Salvage its number-extraction regexes for the lint if useful, then delete the script.
2. **Delete `__BASE_NAME__`** — a LaTeX artifact (`{base}_paper.tex`); the Quarto book has no base-name. Occurs at `step7:4`, `step8:29`.
3. **Delete `__FACTORY__`** — resolved by the instantiation decision (§11 M6: template copied wholesale → `__FACTORY__` ≡ `__PROJECT_PATH__`). Occurs in `step8`, `step14` (not step7). This auto-fixes step 14's broken abstract-examples path.
4. **Add a residual-placeholder guard** to `fill_prompt()` (§5.4 must-do 4) so any future unfilled `__TOKEN__` aborts loudly.

(Note: the triple-underscore `paper_map___N__.md` in `step4_architect*.txt` is **not** a bug — bash `${content//__N__/N}` resolves it correctly.)

### 5.4 Pipeline hardening — mechanical gates (elevated from Oracle review)

**Core principle:** the pipeline's checks are enforced by the runner and scripts, not delegated to fresh LLM sessions that can rationalize their own failures. The review's stage-by-stage stress test found the current runner swallows fan-out failures (`wait || true`), matches verdicts with `head -3 | grep` (a killed project sails through if the verdict lands on line 4), false-triggers the REOPEN loop on any prose mention of `REOPEN_STEP10`, and "continues" into the polish steps after max-reopen — polishing a paper with acknowledged unresolved blocking issues. Five must-do hardening items become first-class template requirements:

1. **Sentinel + fan-out count checks for every step.** Extend `step_output()` (currently only 1a–1e/3/4decide) to all 25 runner steps using the deliverables named in `STEPS.md`; for fan-outs verify the expected file *count* (`extension_brief_[1-7].md`, `paper_map_[1-5].md`, `paper_map_review_[1-5].md`) before touching the `.done` marker; collect child PIDs and `wait $pid` individually in `--parallel` so failures propagate. (Kills the largest silent-failure class.)
2. **Anchored, line-1-only verdict parsing.** `head -1 | grep -q '^VERDICT: KILL'` (1d) and `'^VERDICT: REOPEN_STEP10'` (11); each gate step deletes its own prior output before writing (defeats stale-verdict carryover); on `MAX_REOPEN` exhaustion **halt for human review** rather than continuing into steps 12–15.
3. **Enforce the inline-number mandate mechanically (§6.3), not a prose-vs-log diff.** (a) A **naked-numeral lint** scans `manuscript/*.qmd` prose (outside code chunks and inline `` `r …` `` spans); any disallowed numeric literal fails the build (allowlist: years, IRB/dataset IDs, footnote/enumeration markers, spelled or round rhetorical numbers). This makes prose↔analysis drift *impossible* rather than detecting it after the fact — and replaces `verify_numbers.py` entirely. (b) A **clean-final-render guard** so inline values can't be served stale from a `freeze:`/cache — the final render (after step 15, which can silently alter prose) re-executes or verifies freeze freshness. Both run in the runner at steps 8, 11, and after 15. *Not closed by this:* a valid-but-wrong object reference (`stats$wrong$path`) — a live but wrong number, caught only by human/critic review (no diff script catches it either). *Lighter optional guard:* spot-check headline numbers in the intermediate `findings_brief.md` against `scripts/R/output/*.log`, since the model reasons from them (the step-3 bottleneck) even though final printed numbers are recomputed inline.
4. **Residual-placeholder guard in `fill_prompt()`:** after substitution, `grep -qE '__[A-Z_]+__'` → abort naming the offending token.
5. **Deterministic bibliography pipeline:** one script merges `codex_references.bib` + `argument_references.bib` + `seed.bib` → `manuscript/references.bib` with DOI-first dedup (fallback normalized title+year), **key-collision detection** (same key → different work = hard error), url-field stripping, and a check that every `@key` cited in `manuscript/*.qmd` resolves. Replaces three LLM-transcription hops (the current corruption vector); step 12 then only verifies existence.

**Strongly recommended (fold in if cheap):** a **provenance ledger** (runner appends one JSONL line per step — id, timestamp, prompt-file sha256, engine+model, exit code, output hashes — doubling as prompt-change marker invalidation and the reproducibility record); a **runner-executed render check** (`render.sh pdf` after steps 13/15, fail on nonzero — the one free CI-grade objective check); **`STEP_TIMEOUT` sizing** for the 20–30k-word step 7 (2700s truncates it); and **Dropbox guidance** (instantiate projects outside CloudStorage, or Dropbox-ignore `run_state/`+`logs/` so parallel fan-outs don't create conflicted marker files that break resume).

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

### 6.3 Numbers-in-prose mandate (dynamic-document discipline)

The template makes explicit what both style sources only imply. `claude-style-kit`'s `r-quarto-style.md:174–231` specifies *how* to build inline values (one nested `stats` object; prose indexes-and-formats only; pre-formatted `*_lab` fields) but scopes itself to code + inline values, *not* prose (`:11–12`). `cc_moral_economy`'s `r-style-notebooks.md:64` says only "Inline R code for statistics so numbers update automatically." Neither is a hard rule. The template adds one:

> **Every statistical number in manuscript prose is an inline `` `r stats$…$lab` `` lookup from a live results object. No naked numeric literals in prose** (allowlist: years, IRB/dataset IDs, footnote/enumeration markers, spelled or round rhetorical numbers). Numbers in tables/figures come from `modelsummary`/`tinytable`/ggplot objects — never typed.

This is the primary defense against prose numbers diverging from the analysis; it is enforced by the §5.4 naked-numeral lint and the clean-final-render guard, and it replaces the LaTeX-era `verify_numbers.py` diff entirely. It does not, by itself, catch a valid-but-wrong object reference (§5.4).

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

### 7.4 Grove hardening (elevated from review)

- **Project-scoped corpus hygiene.** `GROVE_DB` defaults to a single shared DB; the generic tag `seeds` would silently blend corpora across projects (`similar`/`gaps` would mix WildChat with moral-economy). Convention: tag = `<project-slug>_seed` (e.g. `wildchat_seed`); optionally a per-project `GROVE_DB` via `.claude/settings.json` env.
- **Stage 2 is the mechanical verifier of Stage 1**, even when the full depth pass is skipped: `grove acquire --doi` reconciles each report-supplied DOI against the resolved OpenAlex title and reports per-DOI failures loudly (catches hallucinated/mis-transcribed DOIs from the human handoff — the epistemic single point of failure).
- **Saturation stop condition.** Loop `grove expand-frontier` → `grove saturation` until no new anchors (CLI machinery already exists) rather than a fixed depth.
- **`seed.bib` is grounding/verification input, not the final bibliography.** Grove's export carries title/author/year/journal/doi but not volume/issue/pages (schema limit); extending it is grove backlog, not template scope. Final entries flow through the deterministic bib pipeline (§5.4).
- **Codex web gap.** The web-search allowlist hooks are Claude-only; `codex` step 1a runs without domain gating, so hallucinated `codex_references.bib` entries survive until the number/bib gates. Document; the bib pipeline is the backstop. `--skip-codex` also silently collapses step 2's "dual independent analysts" into Claude-vs-Claude — document the epistemic degradation.
- **Prereqs:** set `OPENALEX_EMAIL` (polite pool; grove's default is a placeholder `grove-lit@example.com`); pre-warm the SPECTER embedding model in `make setup`; `grove index` before `similar`.

---

## 8. Florilegium integration (Sub-project C)

### 8.1 Paper theme (Quarto extension)

- Installed via a `Makefile` `setup` target that runs `quarto add` against the `quarto-florilegium` repo (tarball via `gh` while private — mirroring clo-author's Makefile pattern). **No vendored copy** in the template; single source of truth = `quarto-florilegium`.
- `manuscript/_quarto.yml` declares `format: florilegium-pdf` (optional `asq-*` formats available). Font fallbacks (EB Garamond / Inter) documented for machines without Adobe fonts.

### 8.2 Plot theme (ggplot)

- **Vendored copy** `R/theme_florilegium.R` in the template, exposing **`theme_florilegium()`** (alias/rename of `theme_ruling_pen()`), palette `fl_pal`, and `fl_minus` label formatter. **Single-source honesty (review C6):** unlike the paper extension (genuinely install-on-setup, single source `quarto-florilegium`), the plot theme is a vendored copy with `florilegium-plot-theme` as the canonical upstream design source — the copy is regenerated from upstream, not independently edited (R theme scripts have no `quarto add` equivalent unless packaged; packaging deferred per §10). §14 corrected accordingly — do not claim both themes are single-source.
- **Font-family guard (review Part 4):** `theme_florilegium()` must parameterize or fallback-guard all three internal families — `"Minion Pro"`, `"Minion Lin"`, `"Minion SC"` are hard-coded in `theme_ruling_pen.R:53,62,66`, so a `base_family` override does not reach them. On machines without Minion, fall back to EB Garamond variants so figures don't emit blank glyphs.
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
| `grove` | Merge `feat/bibtex-import` → `main` (contains `import-bibtex`, `acquire --doi`/`tag`, multi-id `expand`, `clusters`, `similar --tag`, `gaps --by`). **This merge must precede M4** — every Stage-2 command the lit phase uses is branch-only today (review C7). Decide on experimental `feat/discovered-works-cache` (merge or park with a note). The `grove-research` skill **already exists** (`.claude/skills/grove-research/SKILL.md`) — review/refine, don't rebuild. Confirm test suite green post-merge. |
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
- **M4 — Grove + two-stage lit search (D).** **Prerequisite: merge grove `feat/bibtex-import` → `main`** (the Stage-2 commands are branch-only, review C7). Then: `litphase_*` prompts; `settings.json` grove perms (`Bash(grove:*)`); project-scoped tags; documented prereqs. Verifiable: dry-run the lit phase on a toy brief → `literature_map.md` + `seed.bib` produced (Stage 2 exercised against a live grove DB with per-DOI reconciliation). ⛔
- **M5 — Component housekeeping (E, remainder).** style-kit `git init`; florilegium rename/de-vendor; grove `feat/discovered-works-cache` decision; `grove-research` skill review. Verifiable: style-kit has commits; florilegium exposes `theme_florilegium()`; grove tests green on `main`. ⛔
- **M6 — Instantiate `wildchat-tbv`.** Instantiation mechanism = **copy the template repo wholesale** into the project dir, then `git init` (drop upstream history); fill `project_brief.md`; `make setup`; run the lit phase; smoke-test the first pipeline steps end-to-end. Verifiable: a real `literature_map.md` and initial pipeline artifacts for the WildChat project. ⛔

Milestones map to sub-projects A→E→validation. B, C, D develop against the M1 spine and are reviewed independently; the **grove `main` merge is the one E item that must land before M4**, the rest of E proceeds in parallel once M1 stabilizes.

---

## 12. Validation & testing

- **Template smoke test:** `run_prompts.sh` dry-run enumerates steps; placeholder `manuscript/` renders to PDF via `make render`.
- **Style gate:** `make lint` (lintr + ruff) passes on the template's own R/Python.
- **Florilegium render:** a canonical figure (via `theme_florilegium()`) and a `modelsummary`/`tinytable` regression table (with `notes=`) render correctly (SE grouping active) in the florilegium PDF.
- **Lit phase dry-run:** toy `project_brief.md` → Stage-1 synthesis → Stage-2 grove seed/expand/similar/gaps → `literature_map.md` + `seed.bib`. Requires a reachable grove install + DB.
- **Grove regression:** `grove` test suite green after the `feat/bibtex-import` merge.
- **Mechanical gates (§5.4):** unit-test the runner's sentinel/count checks, anchored verdict parsing, `fill_prompt()` placeholder guard, the naked-numeral lint, and the bib-merge script against fixtures (killed-verdict-on-line-4, partial fan-out, unfilled placeholder, naked numeral in prose, duplicate bib key) — each must fail loudly, not pass silently.
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
8. **The human Deep-Research handoff is the epistemic single point of failure.** Everything downstream inherits Stage 1's quality unchecked (hallucinated DOIs, stale/partial pastes). Mitigation: Stage 2 mechanically verifies the seed set (per-DOI OpenAlex reconciliation) even when the depth pass is skipped; stamp reports with date + source model; require a DOI+title table, not free prose.
9. **Confident-slop meta-risk.** Steps 12–15 are *polishers* — they make a wrong paper look immaculate, and the max-reopen "continue anyway" path feeds them exactly that. Mitigation: the mechanical triad (§5.4 sentinels + number gate + bib lint) plus halting on max-reopen; polish is never reachable with known-unresolved blocking issues.
10. **Grove DB state leaks between projects.** The shared default DB + a generic tag silently blends corpora. Mitigation: project-scoped tags / per-project `GROVE_DB` (§7.4).
11. **Evaluation vacuum.** With `quality.md`'s scoring dropped, remaining gates are LLM self-assessment. Mitigation: a short *mechanical* submission checklist consumed at step 11 (numbers verified by script, figures/tables render, every citation resolves, sample path disclosed, render exits 0), plus keeping human pauses at 1d / 4decide / 11 as the real quality gate.
12. **Model/version drift.** Fresh sessions pin no model version; a rerun months later is a different factory. Mitigation: the provenance ledger (§5.4) records engine+model per step; optional pinning via `CLAUDE_BIN`/`CODEX_BIN` flags.

---

## 14. Success criteria

- `claude_paper_factory` (branch `feat/quarto-native-rebuild`) contains a clean, de-specialized, Quarto-native prompt-pipeline paper factory with **no** clo-author agent scaffold.
- House style = claude-style-kit canonical + the single documented table override + the retained prose/writing layer; lint gate runs.
- Florilegium **paper** theme installs on `make setup` (single source: `quarto-florilegium`); the **plot** theme is vendored from its upstream `florilegium-plot-theme`, font-fallback-guarded, and actually wired into rendered output via `theme_florilegium()`.
- The two-stage literature workflow produces a verified `literature_map.md` that grounds the pipeline, with grove as an external dependency and Stage 2 optional.
- grove, claude-style-kit, and the florilegium repos are versioned, up to date, and mutually integrable.
- `wildchat-tbv` is instantiated from the template and passes the end-to-end smoke test.
```
