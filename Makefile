# Project task runner. Everyday rendering is plain `quarto render`; these targets
# are the few multi-step / one-time operations that YAML can't express.

.PHONY: help setup render preview lint check

help:
	@echo "make setup    install the R + Python toolchain (M3 also installs the florilegium/asq Quarto extensions)"
	@echo "make render   render the manuscript book (M1: HTML; M3: florilegium PDF)"
	@echo "make preview  render the HTML preview"
	@echo "make lint     lint R (lintr) and Python (ruff, correctness only)"
	@echo "make check    lint + render — work is not done until this passes"

# One-time bootstrap: restore the pinned R toolchain from renv.lock (R >= 4.6).
setup:
	Rscript -e 'if (!requireNamespace("renv", quietly = TRUE)) install.packages("renv", repos = "https://cloud.r-project.org"); renv::restore(prompt = FALSE)'
	@echo "note: 'uvx ruff' auto-installs ruff on first use — no pip step needed."
# M3 appends the house Quarto extensions here (needs `gh auth login`):
#   gh api repos/simonfriis/quarto-florilegium/tarball/main > /tmp/florilegium.tar.gz && cd manuscript && quarto add /tmp/florilegium.tar.gz
#   gh api repos/simonfriis/quarto-asq/tarball/main          > /tmp/asq.tar.gz         && cd manuscript && quarto add /tmp/asq.tar.gz

render:
	cd manuscript && ./render.sh

preview:
	cd manuscript && quarto render --to html

lint:
	Rscript -e 'lintr::lint_dir()'
	uvx ruff check .
	python3 scripts/python/lint_prose_numbers.py

check: lint render
