# Domain Profile

<!--
Calibrates all agents for this project: the moral economy of labor and technology.
Working title: "The Moral Economy of Labor and Technology." The paper studies
demand-side moral resistance to new technologies — when and why people judge that
AI should not perform certain work even if it can — and how those judgments
constrain or enable technology adoption and shape the labor market. Survey-based,
observational (no experiment). Field spans economic sociology, the sociology of
work and labor, and economics of automation.
-->

## Field

**Primary:** Economic sociology (markets, morality, and valuation); sociology of work and labor.
**Adjacent subfields:** Economics of automation / future of work; stratification; moral philosophy of markets; technology and society.

---

## Target Journals (ranked by tier)

<!-- The Orchestrator uses this for journal selection. The Librarian prioritizes these in searches. -->

| Tier | Journals |
|------|----------|
| Core target journals | American Journal of Sociology, American Sociological Review, Administrative Science Quarterly |
| Top general / field sociology | Social Forces, Theory and Society, Socio-Economic Review, Sociological Science |
| Top economics & interdisciplinary | QJE, AER, JPE, Journal of Economic Perspectives, PNAS, Nature Human Behaviour |
| Top management / org theory | Organization Science, Management Science, Strategic Management Journal |
| Methods | Sociological Methods & Research, Sociological Methodology |

---

## Common Data Sources

<!-- The Explorer prioritizes these. The explorer-critic knows their quirks. -->

| Dataset | Type | Access | Notes |
|---------|------|--------|-------|
| Original survey (this project) | attitudinal microdata | restricted (IRB24-0098, IRB24-0756) | 2,357 respondents (quota-matched to the U.S. Census on age, sex, race, and political affiliation) each rating 10 of 940 occupations on whether AI can/should assist vs. automate, plus a multi-item moral-repugnance scale. A 300-respondent scale-development study validates the instrument. The core demand-side measure. |
| O*NET | occupational attributes | public | Tasks, work activities, work context, skills, abilities by SOC occupation. Used to characterize what occupations involve and to model which job features predict moral resistance. |
| BLS OEWS / CPS / Employment Projections | occupational employment & wages | public | Employment levels, wages, demographic composition, and projected growth by occupation. The labor-market outcomes/covariates side. |
| AI-exposure measures | derived occupational scores | public | Eloundou, Manning, Mishkin & Rock ("GPTs are GPTs", 2024); Felten, Raj & Seamans (AI Occupational Exposure); Webb (2020, "The Impact of Artificial Intelligence on the Labor Market"); Frey & Osborne (2017). Used to separate *technical* automatability from *moral* acceptability — the paper's key distinction. |
| ACS / Census occupational data | demographic composition | public | Worker demographics by occupation, for representativeness and stratification analysis. |
| Consumer / public-opinion surveys (Pew, GSS modules, Eurobarometer) | attitudinal | public | External benchmarks for attitudes toward automation and AI; useful for situating the survey and external validity. |

---

## Common Identification & Inference Strategies

<!-- The Strategist considers these first. The strategist-critic knows field-specific threats. -->

This is a **measurement-and-descriptive** project, not a design-based causal one: there
is no experiment. The credibility of the contribution rests on construct validity of the
moral-repugnance measure and on careful descriptive and correlational inference, with
causal language reserved for where it is genuinely defensible.

| Strategy | Typical Application | Key Assumption / Threat to Defend |
|----------|-------------------|------------------------------------|
| Scale development & validation | Establishing that the repugnance items form a coherent, distinct construct (vs. mere automatability beliefs, disgust, or generic technophobia) | Dimensionality (EFA/CFA), reliability, convergent/discriminant validity. The 300-respondent study is the validation sample; report factor structure and item performance. |
| Multilevel / within-between decomposition | Respondents nested in (and crossed with) occupations; separating person-level from occupation-level variation in repugnance | Correct random-effects structure; do not conflate who-is-rating with what-is-rated. Cluster/most-conservative SEs on the relevant level(s). |
| Occupation-level descriptive mapping | Which occupational features (O*NET task content, social vs. technical work, AI exposure) predict aggregate moral resistance | Aggregation choices and measurement error in occupation scores; sample of raters per occupation. Distinguish description from explanation. |
| The technical-vs-moral wedge | Comparing AI *capability* beliefs to *should* judgments to isolate moral resistance net of perceived automatability | The wedge is not an artifact of scale framing or acquiescence; show it survives controls for capability beliefs and demographics. |
| Demand-side ↔ labor-market linkage | Relating occupation-level moral resistance to adoption proxies, employment/wage levels, and projected change | Confounding (occupations differ on many dimensions); reverse causality; selection. Treat as conditional association unless a credible source of exogenous variation is found; consider shift-share/exposure designs as a future extension, not a current claim. |
| Survey-quality and bias checks | Attention/speeding filters, acquiescence, common-method variance, Prolific-sample composition | Robustness of patterns to quality screens and to reweighting toward population benchmarks. |

---

## Field Conventions

<!-- The Coder and Writer follow these. The writer-critic checks for them. -->

### General conventions (apply across target journals)

- **Background as conceptual argument:** build a theoretical argument (the moral economy of who-should-do-what work), not a "literature review." Motivate why moral constraints on technology matter, not merely that they are understudied.
- **Construct first:** because the dependent variable is an attitudinal construct, lead with its definition and validation. Reviewers will not accept downstream analysis until the measure is credible.
- **Levels of analysis:** be explicit and consistent about respondent-level vs. occupation-level claims. Most-conservative clustering for the level of inference.
- **Scales/indices:** report reliability and dimensionality; show the index is not reducible to a single item or to perceived automatability.
- **Mechanisms:** sociology and economics referees both expect more than a headline association — heterogeneity (by occupation features, respondent values/politics), and evidence on the technical-vs-moral distinction.
- **Effect sizes in substantive units:** report on the response scale and as standardized/marginal effects; avoid log-odds in the reader's head.

### AJS / ASR-specific conventions

- **Theory as contribution:** the paper must change how we understand the relationship between moral judgment, markets, and the labor market — not just document attitudes. Connect to the moral-economy and contested-markets traditions.
- **Citation style:** ASR/AJS house styles (author-date). For an ASQ submission, APA (adopted Jan 2025). The manuscript supports both via the `florilegium` (Chicago) and `asq` (APA) Quarto formats.
- **Significance:** report `*` p<.05, `**` p<.01, `***` p<.001; for ASQ, do not report p<.10.
- **Length / leanness:** keep the main manuscript focused; move scale psychometrics, robustness, and supplementary occupation analyses to an appendix/online supplement.
- **Interdisciplinary legibility:** the audience spans sociology and economics — define constructs on first use; avoid subfield jargon.

---

## Notation Conventions

<!-- The Writer and writer-critic enforce these. -->

| Symbol | Meaning | Anti-pattern |
|--------|---------|-------------|
| $Y_{ij}$ | Outcome (e.g., repugnance) from respondent $i$ for occupation $j$ | Don't use $y$ without subscripts |
| $R_{ij}$ | Moral-repugnance index (respondent × occupation) | Define the index explicitly; don't conflate with a single item |
| $A_{j}$ | AI-exposure / automatability of occupation $j$ | Distinguish capability ($A$) from "should" judgments |
| $X_{i}$ | Respondent covariates (demographics, politics, AI use) | Define controls vs. moderators |
| $W_{j}$ | Occupation covariates (O*NET task content, employment, wages) | Keep occupation- vs. person-level covariates distinct |
| $\alpha_i, \gamma_j$ | Respondent and occupation random/fixed effects | Don't reuse one symbol for both levels |
| $\varepsilon_{ij}$ | Idiosyncratic error | Don't use $e_{ij}$ (looks like a variable) |

---

## Seminal References

<!-- The Librarian ensures these are cited when relevant. The strategist-critic knows their methods. -->

### Moral economy
| Work | Why It Matters |
|------|---------------|
| E.P. Thompson (1971), "The Moral Economy of the English Crowd in the Eighteenth Century," *Past & Present* | The foundational statement of *moral economy* — shared norms about legitimate economic conduct that constrain markets. Anchors the paper's title and frame. |
| James C. Scott (1976), *The Moral Economy of the Peasant* | Extends moral economy to subsistence ethics and the legitimacy of economic arrangements; canonical companion to Thompson. |
| Andrew Sayer (2000/2007), "Moral Economy and Political Economy"; *Why Things Matter to People* | Contemporary theorization of moral economy as the normative evaluation of economic practices; bridges to valuation. |

### Markets, morality, and contested commodification
| Work | Why It Matters |
|------|---------------|
| Alvin E. Roth (2007), "Repugnance as a Constraint on Markets," *JEP* | The economics of repugnance — objections that persist even when a transaction is efficient. Direct precedent for the performance-insensitive structure of the survey's repugnance items. |
| Viviana Zelizer (1979 *Morals and Markets*; 1994 *The Social Meaning of Money*) | How moral and social meanings shape what may be marketized; sacred/market boundaries. |
| Marion Fourcade & Kieran Healy (2007), "Moral Views of Market Society," *Annual Review of Sociology* | Synthesizes the moralized understanding of markets; map of the terrain this paper enters. |
| Michael Sandel (2012), *What Money Can't Buy*; Debra Satz (2010), *Why Some Things Should Not Be for Sale*; Margaret Jane Radin (1996), *Contested Commodities* | The philosophy of moral limits to markets — what should and should not be commodified, and why. |
| Kieran Healy (2006), *Last Best Gifts*; Michel Anteby (2010), "Markets, Morals, and Practices of Trade," *ASQ*; Rene Almeling (2011), *Sex Cells* | Empirical sociology of morally contested markets and how moral boundaries are enacted in practice. |
| Michèle Lamont (2012), "Toward a Comparative Sociology of Valuation and Evaluation," *Annual Review of Sociology* | Framework for how worth and legitimacy are socially constructed — relevant to moral valuation of work. |

### Automation, AI, and the future of work
| Work | Why It Matters |
|------|---------------|
| Autor, Levy & Murnane (2003), "The Skill Content of Recent Technological Change," *QJE*; Autor (2015), "Why Are There Still So Many Jobs?" *JEP* | Task-based framework for what technology can do to occupations — the supply/capability side the paper contrasts with moral acceptability. |
| Acemoglu & Restrepo (2018 *AER*; 2020 *JPE*, "Robots and Jobs") | Canonical estimates of automation's labor-market effects; the outcome side of the demand-side argument. |
| Frey & Osborne (2017), "The Future of Employment"; Webb (2020); Felten, Raj & Seamans (2021); Eloundou, Manning, Mishkin & Rock (2024), "GPTs are GPTs" | Occupational exposure/automatability measures used to separate what *can* be automated from what people think *should* be. (The last is merged into the data.) |
| Brynjolfsson & McAfee (2014), *The Second Machine Age* | Framing reference for the AI-and-work debate. |

### Methods (measurement & inference)
| Work | Why It Matters |
|------|---------------|
| Gerber & Green (2012); Angrist & Pischke (2009) | Reference points for inference discipline even in an observational design. |
| Standard psychometrics (EFA/CFA, reliability, measurement invariance) | The repugnance scale must clear construct-validity bars; cite the conventions the validation study follows. |

---

## Field-Specific Referee Concerns

<!-- The domain-referee and methods-referee watch for these. -->

- **Construct validity (the central concern):** "Does the repugnance scale measure a distinct moral construct, or just disgust, technophobia, or beliefs about what AI *can* do?" Show dimensionality, reliability, and discriminant validity; demonstrate the technical-vs-moral wedge.
- **Description vs. causation:** with no experiment, reviewers will police causal language. Conditional associations must be labeled as such; demand-side → labor-market claims need explicit confounding/selection discussion.
- **External validity:** the Prolific sample was **quota-matched to the U.S. Census/ACS on age, sex, race, and political affiliation**, so it is nationally representative on those dimensions — lead with that rather than treating it as a convenience sample. Residual concerns are non-quota dimensions (education, region, online-panel selection) and whether stated occupation-rating attitudes generalize to behavior/adoption.
- **Levels and dependence:** "Are SEs right given respondents crossed with occupations?" Defend the multilevel structure and clustering.
- **Theoretical contribution:** "How does this change our understanding of markets, morality, and work?" Connect findings to moral economy and contested-markets theory, not just to the AI-policy conversation.
- **Survey method effects:** acquiescence, common-method variance, ordering/framing — show robustness.

---

## Quality Tolerance Thresholds

<!-- Used by quality.md. -->

| Quantity | Tolerance | Rationale |
|----------|-----------|-----------|
| Point estimates | 1e-6 | Coefficients must match logs exactly |
| Standard errors | 1e-4 | Minor MC variability acceptable; stable across runs |
| Scale reliability (alpha/omega) | report to 2 dp | Psychometric reporting convention |
