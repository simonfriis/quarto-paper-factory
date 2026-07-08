# Dependency hints for renv.
#
# This file is never executed. It exists so `renv::snapshot()` (implicit type) records
# the render/lint toolchain — packages the project depends on but that are not referenced
# in chapter/analysis code (Quarto's R engine, the linter, the seeding helper). Add a
# `library(pkg)` line here when a toolchain package should be pinned in renv.lock.

library(knitr)        # Quarto R engine
library(rmarkdown)    # Quarto R engine
library(lintr)        # make lint
library(withr)        # with_seed() reproducibility (house rule)
library(systemfonts)  # theme_florilegium() font-variant registration
library(ragg)         # faithful raster device for figures (agg_png)
