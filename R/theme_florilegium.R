# ============================================================================
# theme_florilegium.R — the house ggplot2 theme ("Ruling Pen"), paired with the
# florilegium manuscript theme. Vendored from the florilegium-plot-theme repo
# (upstream source of truth); regenerate from there rather than editing in place.
#
# A scientific-engraving look: the manuscript's Minion Pro serif with lining /
# tabular numerals, a full ruled frame in fine taupe rules, a faint reading grid,
# a warm monochrome palette, and an open/filled-mark grammar.
#
# Usage (chapter setup chunk or analysis script):
#   source(here::here("R/theme_florilegium.R"))
#   ggplot(df, aes(x, y)) + geom_*(...) + theme_florilegium()
# Render with a device that resolves OpenType figure styles:
#   ggsave("fig.png", p, device = ragg::agg_png, dpi = 300)   # raster, faithful
#   # cairo_pdf for vector (the manuscript renders figures with cairo_pdf).
#
# Fonts: Minion Pro (commercial). If it is not installed, the theme falls back to
# EB Garamond (a metric-compatible free serif), and finally to the generic serif,
# so a machine without Adobe fonts renders clean figures rather than blank glyphs.
# Public API: theme_florilegium(), fl_pal, fl_minus (theme_ruling_pen / rp_* alias).
# ============================================================================
suppressPackageStartupMessages({
  library(ggplot2)
  library(systemfonts)
})

# ── Resolve the figure font + register numeral / small-caps variants, with fallback ──
.fl_families <- local({
  installed <- unique(systemfonts::system_fonts()$family)
  if ("Minion Pro" %in% installed) {
    register_variant("Florilegium Num", "Minion Pro",
      features = font_feature(numbers = c("lining", "tabular")))
    register_variant("Florilegium SC", "Minion Pro",
      features = font_feature(letters = "small_caps"))
    list(base = "Minion Pro", num = "Florilegium Num", sc = "Florilegium SC")
  } else if ("EB Garamond" %in% installed) {
    register_variant("Florilegium Num", "EB Garamond",
      features = font_feature(numbers = c("lining", "tabular")))
    # EB Garamond has no true small caps; use the base family for strip labels.
    list(base = "EB Garamond", num = "Florilegium Num", sc = "EB Garamond")
  } else {
    list(base = "serif", num = "serif", sc = "serif")
  }
})

# ── Palette: warm monochrome + functional greys (roles are fixed) ──
fl_pal <- list(
  ink   = "#1F1813",  # warm near-black: data, axis titles, primary marks
  taupe = "#9A9388",  # fine structural rules: the box, the ticks
  grid  = "#D9D4CB",  # faint horizontal reading grid
  lab   = "#3A352F",  # demoted tick-label ink (keeps the data the darkest thing)
  soft  = "#6E665C",  # secondary grey: error bars, light fits, secondary series
  nsg   = "#8A847C",  # non-significant grey: coefficient de-emphasis (SOLID, not alpha)
  bar   = "#E7E2D9"   # pale bar fill
)
rp_pal <- fl_pal  # back-compat alias for the upstream name

# ── True minus sign (U+2212) for axis labels: scale_*_continuous(labels = fl_minus) ──
fl_minus <- function(x) gsub("-", "−", format(x, trim = TRUE))
rp_minus <- fl_minus

# ── The theme. grid_dirs: gridlines to draw — "y" (default), "x", "xy", or "none". ──
theme_florilegium <- function(grid_dirs = "y", base_size = 9, base_family = .fl_families$base) {
  num_family <- .fl_families$num
  sc_family <- .fl_families$sc
  th <- theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      plot.background = element_rect(fill = "white", colour = NA),
      panel.background = element_rect(fill = "white", colour = NA),
      panel.grid = element_blank(),
      panel.border = element_rect(colour = fl_pal$taupe, fill = NA, linewidth = 0.22),
      axis.ticks = element_line(colour = fl_pal$taupe, linewidth = 0.20),
      axis.ticks.length = unit(1.8, "pt"),
      axis.text = element_text(colour = fl_pal$lab, family = num_family, size = base_size - 1.5),
      axis.title = element_text(colour = fl_pal$ink, size = base_size),
      axis.title.x = element_text(margin = margin(t = 4)),
      axis.title.y = element_text(margin = margin(r = 4)),
      strip.text = element_text(colour = fl_pal$ink, family = sc_family, size = base_size),
      strip.background = element_blank(),
      panel.spacing = unit(8, "pt"),
      legend.position = "none",
      plot.margin = margin(7, 13, 7, 7)
    )
  if (grepl("y", grid_dirs)) {
    th <- th + theme(panel.grid.major.y = element_line(colour = fl_pal$grid, linewidth = 0.13))
  }
  if (grepl("x", grid_dirs)) {
    th <- th + theme(panel.grid.major.x = element_line(colour = fl_pal$grid, linewidth = 0.13))
  }
  th
}
theme_ruling_pen <- theme_florilegium  # back-compat alias for the upstream name
