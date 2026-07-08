# Sociology & Management Writing Conventions

These conventions produce papers in the style expected by top sociology and management journals (ASR, AJS, ASQ, AMJ). All writer and writer-critic agents must enforce them.

---

## 1. Section Conventions

### Introduction (~1,500 words)

- Open with clear statement of the **theoretical question and stakes**. By the end of the first paragraph, the reader should know the current state of understanding.
- **Paragraph 2**: State the paper's core argument at a conceptual level — what the paper *claims*, not what it *studies*. Expressible in 3–4 sentences. A reader should be able to disagree.
- Do NOT say the argument is "surprising in several ways" or enumerate dimensions of surprise. Focus the contribution on the specific scholarly debate this paper changes.
- Frame contributions as an **intervention in existing debates**, not filling a gap.
- A well-chosen illustrative example makes the question concrete. **CRITICAL: Never fabricate examples.** Every example must come from a real, citable source. Check the data first; if not there, use WebSearch. If no suitable example exists, skip it.
- Preview empirical strategy and key findings **qualitatively** — no specific numbers in the introduction.
- The introduction should read as a **sustained argument**, not a summary of the paper's contents.

### Background (~2,000 words)

- Title something **substantive/conceptual**, not "Background" or "Literature Review."
- This section develops the **conceptual argument** that the empirical analysis will assess.
- **Do NOT organize by subfield or tradition** (e.g., one subsection on populism, another on professions). Instead, organize around the paper's own argument. Each paragraph advances one step, citing prior work as evidence, foils, or building blocks.
- Prior research is used **architecturally**: each citation cluster motivates a mechanism, an alternative explanation, or a testable contrast.
- **Do NOT write about "literatures" as such.** Write about the world and ideas; support claims with prior work.
- The theory and findings **MUST align tightly**. If they don't, change the argument to match the evidence.
- A conceptual TikZ diagram can help focus the reader on argument mechanics.

### Data (~1,000 words)

- Use `sample_support.md` as the **authoritative source** for universe, matched sample, main estimating sample, treated clusters, subgroup shares, and sample-path caveats.
- **Data provenance is mandatory.** Every external dataset footnoted with: repository/agency name, specific URL or dataset identifier, date accessed, version/vintage. Never: "county-level election results from a public repository." Always: "County-level presidential election returns from the MIT Election Data and Science Lab, Harvard Dataverse, doi:10.7910/DVN/VOQCHQ, accessed March 2026."
- Include summary statistics table and descriptive figures.

### Methods (~800 words)

- **Identification warnings**: Check findings for any "IDENTIFICATION WARNING" flags. If a causal design failed its pre-trend, first-stage, or balance test, use hedged language:
  - USE: "suggestive," "consistent with," "descriptive evidence that"
  - DO NOT USE: "shows that," "the effect of," "causes"
  - Report both naive and trend-adjusted estimates where available.
- Disclose sample path issues cleanly using `sample_support.md`.

### Results (~2,000 words)

- **Link every result to the argument.** Don't just describe tables — explain what each finding means for the paper's claim.
- **Lead with interpretation, not statistics.** State the substantive finding first, then provide statistical detail. Do not walk through regression tables row by row.
- **Interpret early and often.** After each key result, immediately connect it to the theoretical framework. Do not accumulate coefficients for a single interpretation paragraph at the end.
- **Robustness belongs in the appendix.** In the body, state that results hold under alternatives and cite the appendix table. Do not present specification-by-specification results in the body.
- **Calibrate scope.** For a full results section, calibrate to journal norms (ASQ papers run ~10,000 words total). For subsections, scale proportionally and be more selective with statistical detail — the table has the numbers, the prose carries the argument.
- **Check numbers TWICE.** Every number reported in text must be verified against actual tables and log files. If a number doesn't match, fix it.
- Discuss **substantive/economic magnitude**, not just statistical significance.
- Reference all tables and figures by label.

### Discussion (~800 words)

- **Confront counterarguments with evidence**, not just list limitations. The Discussion should strengthen the argument.
- A brief final paragraph acknowledging remaining limitations is fine — keep it short, don't undermine the claims.
- Dominant tone: **confident interpretation**, not hedging.
- **Do NOT resurrect findings banned in `dropped_findings.md`.**
- The guiding question for implications: **"How does this change the way we think about [the focus of the paper]?"** Depending on genre, theoretical or substantive/policy implications may be primary.

### Conclusion (~500 words)

- Structure: the prior understanding → the puzzle or question → the update (how this changes the way we think about the focus of the paper) → substantive or policy implications where relevant.
- Do NOT mention discarded findings.

### Appendix (mandatory)

- The paper **MUST** include an appendix.
- **Robustness results** go in the appendix, not the body. Body mentions them briefly ("Results are robust; see Appendix Table A3").
- Background results, supplementary analyses, detailed data/methods material all belong here.
- Own numbering: Table A1, A2..., Figure A1, A2... Labels: `tab:a1`, `fig:a1`.
- Include appendix table from `sample_support.md` when sample path is non-trivial.
- When in doubt: **put it in the appendix** and reference from the body.

---

## 2. Guardrail Artifacts

### `sample_support.md` (mandatory — create before drafting)

The canonical sample/reference artifact. Must include:
1. `## Universe And Raw Coverage`
2. `## Match Stages` (N/A if no match stage)
3. `## Main Estimating Samples`
4. `## Treatment Support And Effective Clusters`
5. `## Key Subgroup Shares And Treatment Alignment`
6. `## Headline Findings To Sample Map`
7. `## Disclosure Requirements For The Paper`

Be quantitative. If the estimating sample is materially smaller than the raw panel, list each narrowing step with counts.

### `dropped_findings.md` (mandatory — create before drafting)

Start from the `Findings to Discard` section in `argument_decision.md`. For each item:
- The result or claim
- Source table/figure/do-file
- Why excluded
- Whether banned from Introduction, Discussion, and Conclusion (default: yes)

Later steps may only reintroduce a discarded finding if a review explicitly clears it.

---

## 3. Derobotification Patterns

Every draft gets a derobotification pass. Strip these patterns:

### Structural Patterns
1. **Em dashes** → replace with period + new sentence
2. **Bullet points / lists in prose** → convert to flowing paragraphs
3. **Single-sentence paragraphs** → merge with neighbors
4. **Forced narrative arcs** → remove artificial progression ("First... Second... Finally...")
5. **Rule of three** → vary list lengths, don't always group in threes

### Lexical Patterns
6. **"It's not X, it's Y" constructions** → rewrite directly
7. **Colon-introduced lists** → rewrite as sentences
8. **Formulaic topic sentences** → vary openings
9. **Overused words**: robust, stark, striking, nuanced, landscape, underscore, delve, leverage, foster, garner, interplay, tapestry, pivotal, groundbreaking, additionally
10. **Copula avoidance** ("serves as" instead of "is") → use "is"

### Rhetorical Patterns
11. **Talking about literature gaps** → be direct about what the paper does
12. **Asserting importance** → show it with evidence
13. **"This suggests that" overuse** → vary phrasings
14. **Significance inflation** ("pivotal moment," "groundbreaking") → plain language
15. **Promotional language** → let results speak
16. **Superficial -ing analyses** ("highlighting," "underscoring") → specific claims
17. **Vague attributions** ("experts argue," "scholars have noted") → cite specific papers
18. **Negative parallelisms** ("not merely X but Y") → state positively

### Communication Patterns
19. **Filler phrases**: "It is important to note that," "It is worth noting," "Needless to say," "Interestingly," "Arguably"
20. **Excessive hedging** beyond what methods warrant
21. **Uniform sentence length** → vary rhythm (short declarative sentences break up long analytical ones)

### Academic Adaptation
- Preserve formal register (no forced casualness)
- Keep technical precision (don't simplify estimator names)
- Maintain citation density where needed
- Target: reads like a human sociologist wrote it

---

## 4. Paper Standards

- **Minimum length**: 8,000+ words
- **BibTeX**: No `url` fields (the house bibliography style crashes on them). Omit from every entry. The deterministic bib merge (`scripts/python/merge_bib.py`) strips them.
- **Writing reference**: Read `.claude/references/model-papers-style.json` for patterns extracted from 17 published papers. Study `writing_style` and `quality_markers` sections.
- **Terminology discipline**: For vocabulary register matching, the three levels of abstraction, the three-tier fix protocol (autonomous / batch / consultation), and the project vocabulary scaffold, see `.claude/references/terminology-discipline.md`. Apply during all empirical-chapter revisions and writing.
- **Citations**: pandoc syntax (`@key` textual, `[@key]` parenthetical, `[-@key]` year-only); CSL via `manuscript/chicago-author-date.csl`. Booktabs for all tables. Notes via the `notes =` argument of `modelsummary`/`tinytable`, or in the chunk's `#| tbl-cap` / `#| fig-cap`. Render with `manuscript/render.sh`.
- **Author field**: taken from `project_brief.md` (`## Author`); the runner substitutes it into the step prompts as `__AUTHOR__`.
