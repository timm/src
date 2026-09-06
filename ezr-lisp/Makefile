-include $(shell git rev-parse --show-toplevel)/Makefile

docs/nav.inc: index.md ## shared nav = index's 1st <center>
	@awk '/^<center>/{f=1} f; /^<\/center>/{exit}' $< > $@

docs/index.html: NAV =
docs/%.html:     NAV = -B docs/nav.inc
docs/%.html: %.md docs/head.inc docs/nav.inc
	@pandoc --template=docs/page.tmpl \
	  --syntax-highlighting=none -f markdown \
	  -M pagetitle="ezr: $*" -H docs/head.inc $(NAV) $< -o $@
	@open $@
