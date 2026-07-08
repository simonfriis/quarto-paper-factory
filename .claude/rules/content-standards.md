---
paths:
  - "**/*.R"
  - "**/*.py"
  - "**/*.jl"
  - "**/*.tex"
  - "manuscript/**/*.qmd"
  - "master_supporting_docs/**"
  - "explorations/**"
---

# Content Standards: Tables, Figures, PDFs, and Explorations

---

## 1. Table Standards

**Target:** Publication-quality tables matching AER, QJE, ASR, AJS formatting.

### Package choice: modelsummary + tinytable, nothing else

The project standardizes on two packages, and only two:

- **Regression tables → `modelsummary`.** It handles side-by-side comparison, stars, coefficient renaming, GOF rows, and custom standard errors in one call. Its default backend since v2.x is `tinytable`, which is what we want.
- **Descriptive, summary, or any other custom table → `tinytable::tt()`.** For grouped columns use `group_tt(j = ...)`; for numeric formatting use `format_tt()`; for per-row or per-cell styling use `style_tt()`. Captions and notes go in the `caption =` and `notes =` arguments directly.

Both render native HTML and native LaTeX without format-branching. That is the whole reason the project picked them.

Everything else is out:

| Don't use | Why |
|-----------|-----|
| `gt` | Not a first-class LaTeX renderer; HTML-only |
| `kableExtra` | Redundant with tinytable; dual-format story is weaker |
| `stargazer` | Unmaintained; no HTML story |
| `xtable` | Outdated |
| `knitr::kable()` | Fine for trivial one-offs, not for publication tables |
| `fixest::etable` | Produces great-looking LaTeX but no HTML; use `modelsummary(fixest_fits, ...)` instead |

If a specific table needs something neither package can do, the answer is to style it with tinytable's primitives, not to pull in another backend.

### Core principles

- Three-line format: `\toprule` / `\midrule` / `\bottomrule`. Zero vertical rules. No `\hline`.
- No titles or notes inside the table body. Captions go in the chunk's `tbl-cap:` (Quarto) or the package's `caption =` argument. Notes go in the package's `notes =` argument, which both packages render as a width-constrained justified paragraph below the table — no `threeparttable` required.
- Human-readable variable names, not raw R names (`Log wages`, not `ln_wage_deflated`).
- Coefficient display: point estimates on one row, standard errors in parentheses on the row below. Stars: `+` p<0.1, `*` p<0.05, `**` p<0.01, `***` p<0.001 (or the project-local `star_levels`). GOF rows at the bottom: Observations, R², fixed-effects indicators, controls.

### modelsummary — recommended pattern

```r
modelsummary(
  models,
  stars      = star_levels,
  stars_note = FALSE,
  coef_map   = c("treatment" = "Treatment", "log_income" = "Log income"),
  gof_map    = c("nobs", "r.squared", "adj.r.squared"),
  escape     = FALSE,
  notes      = paste(
    "\\textit{Notes:}",
    "Standard errors clustered by respondent in parentheses.",
    sig_legend
  )
)
```

A few points the repeated pattern bakes in:

- `stars_note = FALSE` suppresses modelsummary's auto-generated stars-legend note row so the significance legend only appears once, embedded inside the main `notes` string.
- `escape = FALSE` lets `\textit{Notes:}` and `\cref{tbl-foo}` render inside the `notes` string.
- `notes` is a single paste'd string so tinytable renders one justified paragraph, not a stack of bullets.

### tinytable — recommended pattern

```r
df |>
  tinytable::tt(
    caption = "Descriptive statistics by occupation group.",
    notes   = "\\textit{Notes:} N = 23,570 respondent-occupation ratings."
  ) |>
  tinytable::group_tt(j = list(
    "Current AI" = 2:4,
    "Future AI" = 5:7
  ))
```

For panels (A / B / C within a single table), use `group_tt(i = ...)` for row groupings.

### Panel structure (when needed)

`tinytable::group_tt(i = list("Panel A: Full sample" = 1:10, "Panel B: Subset" = 11:20))` creates labeled row groups with a rule between them.

### Prohibited patterns

| Pattern | Reason |
|---------|--------|
| Title row inside the table body | Titles go in chunk `tbl-cap:` or `caption = ` |
| Notes embedded in the table body | Notes go in the package's `notes = ` argument |
| `\hline`, vertical rules | Use booktabs; no vertical rules in target journals |
| Raw variable names (`sex_2`, `ln_wage`) | Human-readable labels required |
| `stargazer`, `xtable`, `kableExtra`, bare `gt` | Use modelsummary or tinytable |
| `fixest::etable` for publication-ready tables | Use `modelsummary(fixest_fits, ...)` |
| `threeparttable` wrapper | tinytable's `notes = ` handles note alignment natively |

---

## 2. Figure Standards

**Target:** Publication-quality figures for sociology and economics journals.

### Core Rules

- **Never add titles or subtitles inside ggplot** — use `labs(title = NULL, subtitle = NULL)`
- **Figure caption lives in the chunk** — `#| fig-cap:` (and `#| label: fig-foo` for cross-refs), not inside the plot
- **Panel labels are the exception** — "Panel A: Employment" inside multi-panel figures is fine
- **Axis labels must be publication-quality** — "Employment Rate" not "emp_rate"

### Dimensions and Style

- **Size:** 540×324pt (5:3 aspect ratio) for single-panel figures
- **Format:** Vector PDF only (`ggsave("fig.pdf")`). PNG only for raster content.
- **Fonts:** Serif throughout — `theme(text = element_text(family = "serif"))` or `theme_minimal(base_family = "serif")`
- **Colors:** Colorblind-friendly palettes — `scale_color_brewer(palette = "Set2")`, `viridis`, or similar
- **Color-independent design:** Combine color with shape and linetype so figures are readable in grayscale
- **X-axis years:** Show all years when panel ≤ 20 years; thin labels only when they overlap

### Figure width

- Single-panel: `#| fig-width: 5.625` (≈ 540pt at 96 dpi) — Quarto/florilegium then sizes it to text width.
- Side-by-side panels: build a single multi-panel figure (`patchwork`, `cowplot`) at the same width; do not lay out two figures with explicit widths.

### Quarto figure chunk

```{r}
#| label: fig-foo
#| fig-cap: "Short descriptive caption."
#| fig-width: 5.625
#| fig-height: 3.375

ggplot(df, aes(x, y)) + geom_point() + theme_minimal(base_family = "serif")
```

Reference in prose with `@fig-foo`. Detailed notes go in the same caption (or in a paragraph immediately following), not in a separate `\note{}` macro.

---

## 3. PDF Processing

### The Safe Processing Workflow

**Step 1: Receive PDF Upload**
- User uploads PDF to `master_supporting_docs/supporting_papers/` or `supporting_slides/`

**Step 2: Check Properties**
```bash
pdfinfo paper_name.pdf | grep "Pages:"
ls -lh paper_name.pdf
```

**Step 3: Split into Chunks**
```bash
mkdir -p paper_name/
for i in {0..9}; do
  start=$((i*5 + 1))
  end=$(((i+1)*5))
  gs -sDEVICE=pdfwrite -dNOPAUSE -dBATCH -dSAFER \
     -dFirstPage=$start -dLastPage=$end \
     -sOutputFile="paper_name/paper_name_p$(printf '%03d' $start)-$(printf '%03d' $end).pdf" \
     paper_name.pdf 2>/dev/null
done
```

**Step 4: Process Chunks**
- Read chunks ONE AT A TIME
- Build understanding progressively
- Selective deep reading of most relevant sections

---

## 4. Exploration Folder Protocol

**All experimental work goes into `explorations/` first.** Never directly into production folders.

### Folder Structure

```
explorations/
├── ACTIVE_PROJECTS.md
├── [project]/
│   ├── README.md
│   ├── R/
│   ├── scripts/
│   ├── output/
│   └── SESSION_LOG.md
└── ARCHIVE/
    ├── completed_[project]/
    └── abandoned_[project]/
```

### Lifecycle

1. **Create** — `mkdir -p explorations/[name]/{R,scripts,output}` + README
2. **Develop** — work entirely within the exploration folder
3. **Decide:**
   - **Graduate** — copy to production; requires quality >= 80, tests pass. Move to `ARCHIVE/completed_[project]/`
   - **Keep exploring** — document next steps
   - **Abandon** — move to `ARCHIVE/abandoned_[project]/` with explanation

### Graduate Checklist

- [ ] Quality score >= 80
- [ ] All tests pass
- [ ] Results replicate within tolerance
- [ ] Code is clear without deep context
- [ ] README explains approach and findings

---

## 5. Exploration Fast-Track

**Lightweight workflow for experimental work.** Quality threshold: 60/100 (vs 80 for production).

### Steps

1. **Research value check** — Does this improve the project?
2. **Create folder** — `mkdir -p explorations/[name]/{R,scripts,output}` + README + SESSION_LOG.md
3. **Code immediately** — no plan needed. Must: run, produce correct results, goal documented.
4. **Log progress** — append 2-3 lines to SESSION_LOG.md
5. **Decision point** — keep exploring, graduate (upgrade to 80/100), or archive

### Kill Switch

At any point: stop, archive with note, move on. Exploration is inherently uncertain.
