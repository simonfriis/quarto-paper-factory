# Pipeline Steps

The 16-step pipeline driven by `run_prompts.sh` (some steps fan out). The runner marks
a step done only when its **deliverable** exists (`step_check`), so this table is also
the mechanical completion contract. Engine `dual` = Claude + Codex in parallel.

| ID | Prompt | Engine | Fan-out | Deliverable(s) | Gate |
|----|--------|--------|---------|----------------|------|
| 1a | step1a_deep_research | codex | — | `codex_research.md` (+ `codex_references.bib`) | — |
| 1b | step1b_data_wrangle | claude | — | `data_wrangle.md` | — |
| 1c | step1c_key_variables | claude | — | `key_variables.md` | — |
| 1d | step1d_viability_gate | claude | — | `viability_gate.md` | **KILL** (line 1 `VERDICT: KILL`) |
| 1e | step1e_descriptive_map | claude | — | `descriptive_map.md` | — |
| 2 | step2_{claude,codex}_analyst | dual | — | `findings_brief_claude.md` + `findings_brief_codex.md` | — |
| 3 | step3_synthesis | claude | — | `findings_brief.md` | — |
| 4ext | step4_ext1..7 | claude | ×7 | `extension_brief_[1-7].md` | — |
| 4lens | step4_architect | claude | ×5 | `paper_map_[1-5].md` | — |
| 4review | step4_architect_review | claude | ×5 | `paper_map_review_[1-5].md` | — |
| 4audit | step4_auditor | claude | — | `proposal_audit.md` | — |
| 4decide | step4_decider | claude | — | `argument_decision.md` | — |
| 4exec | step4_executor | claude | — | rebuilt `scripts/R/` analysis pipeline | — |
| 5argres | step5_argument_research | claude | — | `argument_research.md` (+ `argument_references.bib`) | — |
| 5audit | step5_data_audit | claude | — | Data Audit appended to `findings_brief.md` | — |
| 6 | step6_methods_audit | claude | — | Methods Audit appended to `findings_brief.md` | — |
| 7 | step7_paper_writer | claude | — | `manuscript/*.qmd` + `sample_support.md` + `dropped_findings.md` | — |
| 8 | step8_code_review | claude | — | `code_review.md` | — |
| 9 | step9_review | claude | — | `review_comments.md` | — |
| 10 | step10_revision | claude | — | `revision_summary.md` | — |
| 11 | step11_final_review | claude | — | `final_review.md` | **REOPEN** (line 1 `VERDICT: REOPEN_STEP10*`) |
| 12 | step12_citation_audit | claude | — | `citation_audit.md` | — |
| 13 | step13_table_formatting | claude | — | `table_formatting.md` | — |
| 14 | step14_abstract | claude | — | `abstract_draft.md` (+ abstract in the book) | — |
| 15 | step15_derobotification | claude | — | `derobotification.md` (final prose edits) | — |

## Gates

- **Viability (1d):** if line 1 of `viability_gate.md` is `VERDICT: KILL`, the run halts
  (`kill_memo.md` explains why). The screen is deliberately weak — kill only for a hard
  structural failure.
- **Reopen (11):** if line 1 of `final_review.md` is `VERDICT: REOPEN_STEP10_TEXT` or
  `..._ANALYSIS`, the runner clears Steps 10–11 and loops back to Step 10 (max 3×). After
  the third, it **halts for human review** — the polish steps (12–15) never run on a paper
  with unresolved blocking issues.

## Fan-out & failure handling

Fan-out steps (`4ext`, `4lens`, `4review`, and the dual Step 2) run concurrently with
`--parallel`; the runner collects each child's PID, fails the step if any child fails,
and verifies the expected output **count** before marking done. A step whose deliverable
is missing is not marked done — re-running resumes from there.

## Mechanical number & bibliography gates

After the review/polish steps (8, 11, 15) the **runner** — not the model — runs the naked-numeral
lint (`scripts/python/lint_prose_numbers.py`) on `manuscript/*.qmd` and logs a loud PASS/FAIL, so a
hardcoded number in prose can never pass silently (spec §5.4/§6.3). After Step 15 (the last prose
pass) it clears `manuscript/_freeze` so the final render re-executes rather than serving stale
cached numbers. The bibliography is assembled deterministically by `scripts/python/merge_bib.py`
(DOI-first dedup, citekey-collision hard-error, url stripping) rather than by LLM transcription.

## Literature phase (pre-pipeline, interactive)

Before Step 1a, run the two-stage literature search — it produces `literature/literature_map.md`,
which Step 1a reads and builds on. Run each step explicitly (the autonomous pipeline skips them):

| Step | Prompt | Deliverable(s) |
|------|--------|----------------|
| `litphase1` | litphase_1_prompts | `literature/deep_research_prompts.md` (for the human to run) |
| `litphase2` | litphase_2_synthesize | `literature/research_brief.md` + `literature/seed_dois.md` |
| `litphase3` | litphase_3_grove | `literature/literature_map.md` + `literature/seed.bib` (grove; optional) |

`./run_prompts.sh --step litphase1` → run the Deep Research prompts, drop reports in
`literature/reports/` → `--step litphase2` → `--step litphase3`. See `CLAUDE.md` for detail.
