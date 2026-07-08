# ==============================================================================
# _setup.R — shared render engine for the manuscript chapters.
#
# Usage: in a chapter's setup chunk,
#   #| label: setup-<chapter>
#   #| include: false
#   source(here::here("manuscript/_setup.R"))
#
# Loads the table/figure toolchain and the modelsummary + tinytable backend so
# every chapter renders tables and figures the same way. Analysis packages
# (fixest, lme4, marginaleffects, ...) are loaded by the analysis scripts that
# need them, not here, to keep the render lean.
#
# M3 wires in theme_florilegium() (replacing theme_minimal below) and the docx
# LaTeX -> PDF -> PNG table hook that matches the florilegium / asq typography.
# ==============================================================================

library(here)
here::i_am("manuscript/_setup.R")     # resolve here() to the repo root
library(tidyverse)
library(modelsummary)
library(tinytable)
library(scales)
library(patchwork)
# ggtext is optional at render time (figures embed pre-rendered PDFs), so load it
# only if installed rather than hard-failing the render.
if (requireNamespace("ggtext", quietly = TRUE)) library(ggtext)

# ── Shared figure theme (serif, no plot titles — captions live in chunks) ──
# M3: replace with theme_set(theme_florilegium()).
theme_set(theme_minimal(base_family = "serif"))

# ── Significance thresholds + legend (one English across every table) ──
star_levels <- c("+" = 0.1, "*" = 0.05, "**" = 0.01, "***" = 0.001)
sig_legend  <- "+ p<0.1; * p<0.05; ** p<0.01; *** p<0.001."

# ── modelsummary backend: tinytable for all formats (house rule) ──
options(modelsummary_factory_default = "tinytable")
# A {stars} glue string in the estimate disables modelsummary's auto legend, so
# the embedded sig_legend stays the single source of truth.
options(modelsummary_estimate = "{estimate}{stars}")

# ── Output directory for saved objects ──
dir.create(here::here("manuscript/_objects"), recursive = TRUE, showWarnings = FALSE)

# ── Git provenance stamp (trace any rendered output back to its commit) ──
git_hash <- tryCatch(
  system("git rev-parse --short HEAD", intern = TRUE),
  error   = function(e) "unknown",
  warning = function(w) "unknown"
)
