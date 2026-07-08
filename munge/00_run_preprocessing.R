# ==============================================================================
# 00_run_preprocessing.R — orchestrate the bronze -> silver cleaning pipeline.
#
# Sources each cleaning script in order. Add 01_clean_*.R, 02_clean_*.R, ... that
# read from data/bronze/ (raw, read-only) and write analysis-ready tables to
# data/silver/. Run once, or whenever raw data changes, before the pipeline:
#   Rscript munge/00_run_preprocessing.R
# ==============================================================================

library(here)
here::i_am("munge/00_run_preprocessing.R")

# List the cleaning scripts in dependency order, then source each one:
# scripts <- c(
#   "munge/01_clean_source.R",
#   "munge/02_clean_survey.R"
# )
# for (s in scripts) { message("Running ", s); source(here::here(s)) }

message("No cleaning scripts defined yet — add 01_clean_*.R and list them above.")
