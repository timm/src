# vim: ts=8 noexpandtab :
SHELL := /bin/bash
.DEFAULT_GOAL := help

help: ## show targets
	@grep -hE '^[a-z-]+:.*## ' Makefile | \
	  awk -F':.*## ' '{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

eg: ## run every project's examples/tests
	cd ezr2     && python3 ezr2-eg.py all
	cd tiny-xai && sbcl --script tiny-xai-eg.lisp --all
	cd luamine  && lua luamine.lua --all

Font ?= 4.5       # pdf font size
Cols ?= 3         # pdf columns
LPC  ?= 113       # lines per pdf column; packs sections

%.pdf: ## project dir -> ~/tmp/src/NAME.pdf via a2ps (make tiny-xai.pdf)
	@src=$$(ls $*/$*.lisp $*/$*.py $*/$*.lua 2>/dev/null | head -1); \
	 test -n "$$src" || { echo "no $*/$*.(lisp|py|lua)"; exit 1; }; \
	 case $${src##*.} in lisp) lang=clisp;; py) lang=python;; \
	   lua) lang=lua;; esac; \
	 mkdir -p ~/tmp/src; \
	 a2ps -Bj --landscape --line-numbers=1 --highlight-level=heavy \
	   --borders=no --pro=color --right-footer="" --left-footer="" \
	   --pretty-print=$$lang --footer="page %p." -M letter \
	   --center-title="$$src" \
	   --font-size=$(Font) --columns $(Cols) -o - \
	   <(awk -v C=$(LPC) 'BEGIN{RS="\f"; ORS=""} \
	      {n=split($$0,L,"\n")-1; \
	       if(NR>1 && pos>0 && pos+n>C){printf "\f"; pos=0} \
	       printf "%s",$$0; pos=(pos+n)%C}' $$src) \
	 | ps2pdf - ~/tmp/src/$*.pdf; \
	 open ~/tmp/src/$*.pdf 2>/dev/null || true
