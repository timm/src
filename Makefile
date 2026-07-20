# vim: ts=8 noexpandtab :
SHELL := /bin/bash
.DEFAULT_GOAL := help

help: ## show targets
	@grep -hE '^[a-z-]+:.*## ' Makefile | \
	  awk -F':.*## ' '{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

sh: ## bash tuned by etc/bashrc
	@here="$(CURDIR)" bash --rcfile etc/bashrc -i

tmux: ## tmux session running tuned bash
	@here="$(CURDIR)" tmux -f etc/tmux.rc new-session \
	  "here='$(CURDIR)' bash --rcfile etc/bashrc -i"

push: ## add+commit+push+status
	@git add -A
	@printf "msg (empty=save): "; read m </dev/tty; git commit -m "$${m:-save}" || true
	@git push
	@git status

eg: ## run every project's examples/tests
	cd ezr-py     && python3 ezr2-eg.py all
	cd ezr-lisp && sbcl --script tiny-xai-eg.lisp --all
	cd attic/luamine  && lua luamine-eg.lua --all
	cd ezr-lua      && lua xai-eg.lua --all
	cd ezr-lua      && lua xaiplus-eg.lua --all

check: ## glossary links <-> headings, then each course's frozen transcript
	@python3 etc/join.py glossary.md $(wildcard */*-eg.py */*-eg.lua */*-eg.lisp)
	@cd ezr-lua && lua xai-eg.lua --check
	@cd ezr-lua && lua xaiplus-eg.lua --check

doc: ## pycco html per source file into docs/<proj>/
	@for p in */; do p=$${p%/}; \
	   [ -f $$p/INSTALL.md ] || continue; \
	   mkdir -p docs/$$p; \
	   rm -f docs/$$p/*.html docs/$$p/*.part docs/$$p/.order; \
	   ( cd $$p && \
	     for src in $$(sh INSTALL.md list); do \
	       e=$${src##*.}; b=$${src%.*}; \
	       case $$e in py|lisp|lua) ;; *) continue;; esac; \
	       g=code; case $$b in *-eg) g=tests;; esac; \
	       printf '%s\t%s\t%s\n' "$$b" "$$src" "$$g" \
	         >> ../docs/$$p/.order; \
	     done; \
	     while IFS="$$(printf '\t')" read -r b src g; do \
	       e=$${src##*.}; \
	       case $$e in lisp) t=scm;; *) t=$$e;; esac; \
	       awk -v ext=$$e -f ../etc/doc.awk $$src \
	         > ../docs/$$p/$$b.$$t; \
	       python3 ../etc/pyccot.py -d ../docs/$$p \
	         ../docs/$$p/$$b.$$t >/dev/null; \
	       rm -f ../docs/$$p/$$b.$$t; \
	       python3 ../etc/nav.py ../docs/$$p/$$b.html; \
	     done < ../docs/$$p/.order; \
	     python3 ../etc/toc.py ); \
	   grep -q 'timm extras' docs/$$p/pycco.css || printf '%s\n' \
	     '/* timm extras */' \
	     '.docs pre { font-size: .7em; line-height: 1.45; }' \
	     '.docs table { border-collapse: collapse; margin: 1em 0 1em auto; }' \
	     '.docs th, .docs td { border: 1px solid #ccc; padding: 2px 8px; font-size: .85em; }' \
	     >> docs/$$p/pycco.css; \
	   ls docs/$$p | grep -c '\.html$$'; \
	 done

Font ?= 4.5       # pdf font size
Cols ?= 3         # pdf columns
LPC  ?= 120       # lines per pdf column; packs sections
ETC  := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))etc

%.pdf: ## project dir -> ~/tmp/src/NAME.pdf via a2ps (make ezr-lisp.pdf)
	@src=$$(ls */$*.lisp */$*.py */$*.lua 2>/dev/null | head -1); \
	 test -n "$$src" || { echo "no */$*.(lisp|py|lua)"; exit 1; }; \
	 case $${src##*.} in lisp) lang=clisp;; py) lang=python;; \
	   lua) lang=lua;; esac; \
	 mkdir -p ~/tmp/src; \
	 cfg=$$(dirname $$(dirname $$(command -v a2ps)))/etc/a2ps.cfg; \
	 rc=$$(mktemp); \
	 printf 'Include: %s\nAppendLibraryPath: %s\n' "$$cfg" "$(ETC)" >"$$rc"; \
	 A2PS_CONFIG=$$rc \
	 a2ps -Bj --landscape --line-numbers=1 --highlight-level=heavy \
	   --borders=no --pro=color --right-footer="" --left-footer="" \
	   --pretty-print=$$lang --footer="$$src :: page %p." \
	   -M letter --center-title="" \
	   --font-size=$(Font) --columns $(Cols) -o - \
	   <(awk -v C=$(LPC) 'BEGIN{RS="\f"; ORS=""} \
	      {n=split($$0,L,"\n")-1; \
	       if($$0==""){printf "\f"; pos=0; next} \
	       if(NR>1 && pos>0 && pos+n>C){printf "\f"; pos=0} \
	       printf "%s",$$0; pos+=n}' $$src) \
	 | ps2pdf - ~/tmp/src/$*.pdf; \
	 rm -f "$$rc"; \
	 open ~/tmp/src/$*.pdf 2>/dev/null || true
