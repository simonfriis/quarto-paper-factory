---
paths:
  - "**/*.qmd"
  - "**/*.R"
  - "**/*.r"
---

# R & Quarto style (academic manuscripts)

Applies to R scripts (`.R`) and Quarto documents (`.qmd`). Distilled from
`STANDARD-r-quarto.md`. Governs **within-chunk R code** and **inline computed values** only —
not manuscript prose. Code is never displayed (`execute: echo: false` is a `_quarto.yml`
baseline). Shares the governing principles in `STANDARD.md` (literate/linear/minimal; standard
idioms; present-tense specs; loud failures; no auto-formatter).

Most sections pair the **chosen** style (`✓`) with the **tempting alternative** (`✗`) — and
here the `✗` is usually the mainstream tidyverse default Claude reaches for first. Match the
`✓`. **One decision at a time:** layout (line breaks, spacing, alignment) is set by the
formatting rule below, never by any other rule.

## Grouping — `.by`, not `group_by()` / `ungroup()`

Use the per-operation `.by =`, especially for a single grouping op.

✓ **Chosen**:

```r
penguins |>
  summarise(
    mean_bill = mean(bill_length_mm, na.rm = TRUE),
    n         = n(),
    .by       = species
  )
```

✗ **Avoid** — the dominant idiom Claude defaults to. It leaves persistent grouped state and
needs a trailing `ungroup()` that is pure ceremony for one summary:

```r
penguins |>
  group_by(species) |>
  summarise(mean_bill = mean(bill_length_mm, na.rm = TRUE), n = n()) |>
  ungroup()
```

## Pipe — native `|>`, never `%>%`

✓ **Chosen**:

```r
penguins |>
  filter(species == "Adelie") |>
  pull(bill_length_mm) |>
  mean(na.rm = TRUE)
```

✗ **Avoid** — magrittr `%>%` is everywhere in existing tidyverse code, so it's the reflex
default; it adds a dependency and a second pipe to reason about. Don't mix the two:

```r
penguins %>%
  filter(species == "Adelie") %>%
  pull(bill_length_mm) %>%
  mean(na.rm = TRUE)
```

## Iteration — `purrr::map` (typed), not `*apply` / `for`

✓ **Chosen** — `map_dbl` makes the return shape explicit (a double vector):

```r
r2 <- penguins |>
  split(~ species) |>
  map(\(df) lm(body_mass_g ~ flipper_length_mm, data = df)) |>
  map_dbl(\(m) summary(m)$r.squared)
```

✗ **Avoid** — `sapply` guesses its return type (vector? matrix? list?) — silent shape
surprises; the `for` variant buries "one model per group" in grow-in-place mechanics:

```r
r2 <- sapply(split(penguins, penguins$species),
             function(df) summary(lm(body_mass_g ~ flipper_length_mm, data = df))$r.squared)
```

## Anonymous functions — `\(x)`, not `~ .x`

✓ **Chosen** — real arguments; works everywhere, not just in tidy-eval contexts:

```r
penguins |>
  summarise(across(ends_with("_mm"), \(x) mean(x, na.rm = TRUE)), .by = species)
```

✗ **Avoid** — the purrr `~ .x` formula is the reflex default; `.x`/`.y` are magic, not
arguments, and only work where tidy-eval supports them:

```r
penguins |>
  summarise(across(ends_with("_mm"), ~ mean(.x, na.rm = TRUE)), .by = species)
```

## Namespacing — attach core, call bare

Attach core packages with `library()` and call them bare. Reserve `pkg::` for an incidental
one-off from an unattached package.

✓ **Chosen**:

```r
library(dplyr)
penguins |>
  summarise(m = mean(bill_length_mm, na.rm = TRUE), .by = species)
```

✗ **Avoid** — `pkg::` on everyday core verbs; verbose noise for the common dialect:

```r
penguins |>
  dplyr::summarise(m = dplyr::n(), .by = species)
```

## Formatting — hand-aligned, no `styler` / `air`

Hand-align `=` columns as notation. Multi-argument calls: open `(`, one argument per line,
`=` aligned, closing `)` dedented (see the `.by` example above).

✓ **Chosen** — name column, meaning column:

```r
limits <- list(
  min_mass    = 2700,   # lightest plausible adult (g)
  max_mass    = 6300,   # heaviest plausible adult (g)
  min_flipper = 170     # below this is a measurement error
)
```

✗ **Avoid** — `styler` / `air` single-space (the R-culture default); the aligned column
dissolves and comment starts jitter:

```r
limits <- list(
  min_mass = 2700, # lightest plausible adult (g)
  max_mass = 6300, # heaviest plausible adult (g)
  min_flipper = 170 # below this is a measurement error
)
```

## Comments — short, atomic (per `STANDARD.md`)

One short, atomic comment above nearly every meaningful line — one action each.

```r
# Drop the two birds with no mass reading.
mass <- filter(penguins, !is.na(body_mass_g))
# Mean mass per species, single grouping.
by_species <- summarise(mass, mean_mass = mean(body_mass_g), .by = species)
```

## Chunk options & labels — `#|`, one per line, always labelled

✓ **Chosen** — one option per line; `fig-` / `tbl-` prefix anything cross-referenced:

```r
#| label: fig-flipper
#| fig-cap: "Body mass rises with flipper length."
#| fig-width: 6
```

✗ **Avoid** — the legacy R Markdown default: packed inline header, often unlabelled, e.g.
`{r flipper, echo=FALSE, fig.cap="...", fig.width=6}`. One long messy-diffing line, and an
unlabelled chunk can't be cross-referenced or named in an error.

## Numbers in prose — mandatory (house rule)

Every statistical number in **manuscript prose** is an inline `` `r stats$…$lab` `` lookup from a
live results object — **no naked numeric literals** (allowlist: years, IRB/dataset IDs,
footnote/enumeration markers, spelled or round rhetorical numbers). Numbers in tables and figures
come from the `modelsummary`/`tinytable`/ggplot objects, never typed. This makes prose↔analysis
divergence structurally impossible; `scripts/python/lint_prose_numbers.py` (run by `make check` and
the pipeline) enforces it. The next section is *how* to build those values well.

## Inline computed values — one nested results object; lookups only

Pull every inline value from **one aptly-named nested results object** built in a setup
chunk; an inline expression may only **index it and format** — all computation lives in a
chunk. Pre-format in the object (a `*_lab` field); shape it nested by domain
(`metric → group → field`).

✓ **Chosen** — build it once, then prose is a clean lookup:

```r
#| label: setup-stats
stats <- list(
  bill_len = penguins |>
    summarise(mean = mean(bill_length_mm, na.rm = TRUE), n = n(), .by = species) |>
    mutate(mean_lab = sprintf("%.1f", mean)) |>
    split(~ species)
)
```

```text
Adelie bills averaged `r stats$bill_len$Adelie$mean_lab` mm (n = `r stats$bill_len$Adelie$n`).
```

✗ **Avoid** — computation inline (Claude's reflex). Un-reviewable, un-testable, re-run every
render, and the sentence is unreadable in source:

```text
Adelie bills averaged `r round(mean(penguins$bill_length_mm[penguins$species == "Adelie"], na.rm = TRUE), 1)` mm.
```

✗ **Avoid** — a pile of flat one-off scalars; the chunk and the namespace sprawl:

```r
adelie_bill_mean <- mean(penguins$bill_length_mm[penguins$species == "Adelie"], na.rm = TRUE)
adelie_n         <- sum(penguins$species == "Adelie")
# ...one variable per fact, repeated for every species and metric
```

## Number formatting — pre-format in the object

✓ **Chosen** — prose prints a label field built in the setup chunk:

```text
Adelie bills averaged `r stats$bill_len$Adelie$mean_lab` mm.
```

✗ **Avoid** — formatting/rounding at the call site; verbose and the precision choice repeats
at every inline expression:

```text
Adelie bills averaged `r scales::number(stats$bill_len$Adelie$mean, accuracy = 0.1)` mm.
```

## Object shape — nested by domain

✓ `stats$bill_len$Adelie$mean` — `metric → group → field`; read at any level.
✗ `stats$adelie_bill_mean` — flat names trap the hierarchy in strings; can't iterate a group.

## Figures, config, callouts

- **Figures & tables:** **`modelsummary` + `tinytable`** tables (house override of the kit's
  `gt`: the florilegium PDF format and its `se-grouping.lua` filter are built for tinytable's
  `talltblr`, emitted only when a `notes =` argument is passed); `fig-`/`tbl-` labels; `@fig-` /
  `@tbl-` cross-refs; every figure has `fig-alt`; ggplot captions live in the chunk, never in the plot.
- **Config:** thin per-document YAML; format and execution defaults (incl. `echo: false`) live
  in `_quarto.yml`.
- **Callouts:** default to none in a manuscript. ✗ Don't sprinkle `::: {.callout-note}` around
  findings; reserve the rare `callout-warning` for a genuine correctness caveat.

## Tooling

- `make check` = `lintr` + the naked-numeral lint + `quarto render`. The document must knit — a
  typo'd `stats$…` path or a broken chunk fails the render loudly, which is the designed behaviour.
- `lintr` for correctness only; do **not** require `pkg::` namespacing.

## Reproducibility

- Scope randomness with `withr::with_seed(<seed>, { … })`, never a bare `set.seed()` (a bare seed
  leaks into every later chunk). Seed every bootstrap, permutation, and simulation.
- The R toolchain is pinned in `renv.lock`; run `make setup` (`renv::restore()`) after cloning.
