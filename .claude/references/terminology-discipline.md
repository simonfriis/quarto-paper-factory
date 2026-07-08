# Terminology Discipline

> **Status:** Living scaffold for *The Moral Economy of Labor and Technology*. The
> reusable methodology below (register matching, the three-tier protocol, the three
> levels of abstraction) is stable. The **project vocabulary** is a seed: the full
> canonical term list is finalized after the architecture phase, once the argument
> and chapter structure exist. Until then, apply the methodology and the seed terms,
> and flag new terms for addition rather than inventing canon. Cited from `CLAUDE.md`
> (Conventions) and `.claude/rules/sociology-conventions.md` (§4).

## Purpose

Keep terminology and register consistent across the manuscript: terms should sit at
the level of abstraction appropriate to each paragraph's function, and vocabulary
choices should be applied consistently across prose, tables, figures, captions, and
any code-side labels that reach the reader.

---

## First principle: register matching

Terminological discipline is a sentence-register problem, not only a word-choice
problem. Each empirical-chapter paragraph has a function — **framing**, **reporting**,
or **bridging** — and that function sets the appropriate level of abstraction. A
register mismatch is a sentence operating at the wrong level for its paragraph.

Not every mismatch is an error; a sentence can earn its place by bridging levels. The
problem is the *silent* level-shift, where the reader cannot tell whether the author is
reporting a finding or asserting a theoretical claim. Fixes, in order of preference:
revise in place to match register; move the sentence to a paragraph where it fits; or
keep the mix but signal the transition ("This pattern is consistent with…").

## Three levels of abstraction (this project)

| Level | Register | Project vocabulary (seed) |
|-------|----------|---------------------------|
| **Level 1 — framing** | Most abstract; theory and stakes | moral economy; moral legitimacy of markets and technology; the social regulation of technological change; contested commodification |
| **Level 2 — mechanism** | Theoretical constructs | moral resistance to technology; **moral repugnance**; demand-side constraint on adoption; the *technical-vs-moral wedge* (what AI *can* do vs. what it *should* do); protected/“sacred” work; automation vs. augmentation as moral categories |
| **Level 3 — reporting** | Concrete; measurement and results | the moral-repugnance index; the seven repugnance items; the "should automate" / "should assist" items; occupation-level repugnance score; AI-exposure / automatability score; O*NET task measures; specific coefficients, Ns, occupations |

Reporting paragraphs and table/figure **notes** stay at Level 3. Framing paragraphs
and main-narrative captions may use Level 2. The Theory chapter *defines* Level 2
vocabulary, so audit it for proliferation/consistency rather than register.

---

## Operating mode: three tiers

### Tier 1 — autonomous fix
Mechanical, unambiguous substitutions; make them directly. Applies everywhere the
label reaches the reader (prose, figures, tables, notes, and code-side labels such as
`coef_map` values, factor levels, and named color/label vectors in `scripts/R/`).
Seed rules (extend as drift is found):

| Find | Replace with |
|------|--------------|
| "moral disgust" / "aversion" used for the construct | **moral repugnance** (the construct's canonical name) |
| "AI assistance" vs "augmentation" used interchangeably | pick one per the architecture decision; until then keep **augmentation** for the should-assist construct |
| raw variable names in reader-facing output (`moral_repugnance`, `curr.should_automate`) | human-readable labels ("Moral repugnance", "Should automate (current AI)") |

NOT in Tier 1 scope: internal R variable names, code comments, function names (deferred to a code-terminology refactor).

### Tier 2 — batch proposal
Changes that are consistent but need a once-over: standardizing person-nouns
("respondents" vs "participants" vs "the public"), unit-of-analysis phrasing
(respondent-level vs occupation-level), and Level-2 mechanism terms appearing inside
Level-3 reporting paragraphs. Collect the affected passages and present the list.

### Tier 3 — consultation
High-visibility, high-stakes wording: the **abstract**, **section/subsection titles**,
and main-narrative figure/table captions that encode the contribution. Flag for
individual review; do not change autonomously.

---

## Scope by manuscript surface

| Surface | Treatment |
|---|---|
| Methods & Results chapters | Full taxonomy applies; most issues live here. |
| Theory chapter | Audit for vocabulary proliferation/consistency (it defines Level 2). |
| Discussion / Conclusion | Light touch; Level 2 with Level 1 framing. Flag Level 3 concreteness that intrudes. |
| Abstract, section titles | Tier 3 — individual review only. |
| Table/figure **notes** | Strict Level 3 reporting language. |
| Table/figure **captions** | Main-narrative items may lean Level 2 (Tier 3 if mechanism vocabulary enters); supporting items stay Level 3 descriptive. Heuristic: *delete the display item — does the argument lose a central plank?* Yes → main-narrative. |
| In-figure labels (axes, legends) | Apply Tier 1; bare condition/scale labels are fine since the caption establishes meaning. |
| **Survey-materials appendix** | Participant-facing survey items are reproduced **verbatim** and are exempt — they are study artifacts, not paper prose. Only meta-language (titles, framing, captions) is subject to the taxonomy. |

---

## To finalize after the architecture phase
- The canonical chapter map (chapter file ↔ role).
- The authoritative main-narrative vs supporting classification of each display item.
- The full Tier 1 substitution table (populated from drift found during writing).
- The settled choice between near-synonyms once the argument fixes their meaning
  (e.g., "moral resistance" as the umbrella vs. "moral repugnance" as the measured
  construct; "augmentation" vs "assistance"; "occupation" vs "job" in formal claims —
  note the survey items themselves say "job").
