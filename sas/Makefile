CH = ch00_front.md ch01_simple.md ch02_before.md \
     ch03_python.md ch04_maths.md ch05_substrate.md \
     refs.md

all: check weave        ## test, then build the book source

help:                   ## list targets
	@grep -E '^[a-z]+:.*##' Makefile | \
	  sed 's/:.*##/	/'

check:                  ## run every demo; any assert kills it
	python3 src/lib_eg.py all

weave: $(CH)            ## build/book.md: prose + code + runs
	python3 etc/weave.py $(CH)

pdf: weave              ## tufte reading edition (portrait)
	pandoc build/book.md --metadata-file=meta.yaml \
	  --citeproc --top-level-division=chapter \
	  --pdf-engine=xelatex -o build/book.pdf

wide: weave             ## landscape 2-col 9pt draft edition
	pandoc build/book.md --metadata-file=meta.yaml \
	  --citeproc --top-level-division=chapter \
	  --pdf-engine=xelatex \
	  -V documentclass=extbook -V fontsize=9pt \
	  -V classoption=twocolumn \
	  -V classoption=openany -V classoption=oneside \
	  -V geometry:landscape -V geometry:margin=1.4cm \
	  -V mainfont="TeX Gyre Pagella" \
	  -V monofont="TeX Gyre Cursor" \
	  -V header-includes= -H etc/wide.tex \
	  -o build/book-wide.pdf

tex: weave              ## standalone .tex, for inspection
	pandoc build/book.md --metadata-file=meta.yaml \
	  --citeproc --top-level-division=chapter \
	  -s -o build/book.tex

data:                   ## fetch example tables (MOOT)
	mkdir -p data
	curl -sL -o data/auto93.csv \
	  https://raw.githubusercontent.com/timm/moot/master/optimize/misc/auto93.csv

lines:                  ## style gate: code>65, prose>85
	awk 'length > 65 {print FILENAME": "FNR": "$$0}' \
	  src/*.py etc/*.py; true
	awk 'length > 85 {print FILENAME": "FNR": "$$0}' \
	  ch*.md; true

setup:                  ## install build deps (debian/ubuntu)
	sudo apt-get install -y --no-install-recommends \
	  pandoc texlive-xetex texlive-latex-extra lmodern
	@echo "macos: brew install pandoc basictex; then:"
	@echo "  sudo tlmgr install tufte-latex extsizes \
	  fvextra hardwrap titlesec xifthen ifmtarg"
