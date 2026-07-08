#!/usr/bin/env bash
# Render the Quarto book.
#
# M1 spine: renders the formats declared in _quarto.yml (HTML). Args pass through
# to `quarto render`, so `./render.sh` and `./render.sh --to html` both work.
#
# M3 replaces this with the multi-format driver used by the pipeline:
#   ./render.sh pdf   -> florilegium typeset PDF
#   ./render.sh docx  -> ASQ Word (with OOXML repair)
#   ./render.sh both  -> florilegium PDF + ASQ Word (stash-and-restore)
#   ./render.sh asq   -> ASQ submission pair (ASQ PDF + ASQ Word)
set -euo pipefail
cd "$(dirname "$0")"
quarto render "$@"
