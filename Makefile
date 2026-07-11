# vim: ts=8 noexpandtab :
SHELL := /bin/bash
.DEFAULT_GOAL := help

help: ## show targets
	@grep -hE '^[a-z-]+:.*## ' Makefile | \
	  awk -F':.*## ' '{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

push: ## add+commit+push+status
	@git add -A
	@printf "msg (empty=save): "; read m </dev/tty; git commit -m "$${m:-save}" || true
	@git push
	@git status

eg: ## run every project's examples/tests
	cd ezr2     && python3 ezr2-eg.py all
	cd tiny-xai && sbcl --script tiny-xai-eg.lisp --all
	cd luamine  && lua luamine-eg.lua --all

doc: ## pycco html per tiny-xai .lisp (order: sh INSTALL.md list)
	@cd tiny-xai && mkdir -p docs && \
	 for f in $$(sh INSTALL.md list); do \
	   b=$${f%.lisp}; \
	   awk -f ../etc/doc.awk $$f > docs/$$b.scm; \
	   python3 ../etc/pyccot.py -d docs docs/$$b.scm >/dev/null; \
	   rm -f docs/$$b.scm; \
	   python3 ../etc/nav.py docs/$$b.html; \
	 done; \
	 python3 ../etc/toc.py; \
	 grep -q 'timm extras' docs/pycco.css || printf '%s\n' \
	   '/* timm extras */' \
	   'p { text-align: right; }' \
	   '.docs pre { font-size: .7em; line-height: 1.45; }' \
	   '.docs table { border-collapse: collapse; margin: 1em 0 1em auto; }' \
	   '.docs th, .docs td { border: 1px solid #ccc; padding: 2px 8px; font-size: .85em; }' \
	   >> docs/pycco.css; \
	 ls docs | grep -c '\.html$$'

Font ?= 4.5       # pdf font size
Cols ?= 3         # pdf columns
LPC  ?= 113       # lines per pdf column; packs sections

%.pdf: ## project dir -> ~/tmp/src/NAME.pdf via a2ps (make tiny-xai.pdf)
	@src=$$(ls */$*.lisp */$*.py */$*.lua 2>/dev/null | head -1); \
	 test -n "$$src" || { echo "no */$*.(lisp|py|lua)"; exit 1; }; \
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
