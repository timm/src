# vim: ts=8 noexpandtab :
include ../../Makefile

MOOT ?= $(HOME)/gits/moot/optimize

%.pdf: ## file in this dir -> pdf, via the root rule
	@cd .. && $(MAKE) -f ../Makefile $*.pdf

holdouts: ## active-vs-random win, all moot sets, 10 cpus
	@mkdir -p ~/tmp
	@ls $(MOOT)/*/*.csv | sort -R | xargs -n1 -P 10 sh -c \
	  'echo "$$(luajit lib.lua --DATA=$$(dirname $$1)/ \
	    --file=$$(basename $$1) --holdouts) $$1"' _ \
	  | tee ~/tmp/holdouts.log
	@echo; awk '{print int($$2+0.5)}' ~/tmp/holdouts.log | \
	  sort -n | awk '{printf "%4d", $$1; \
	    if (NR%16==0) print ""} END{if (NR%16) print ""}'
