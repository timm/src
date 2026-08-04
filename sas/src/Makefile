# vim: ts=8 noexpandtab :
include ../../Makefile

MOOT ?= $(HOME)/gits/moot/optimize

%.pdf: ## file in this dir -> pdf, via the root rule
	@cd .. && $(MAKE) -f ../Makefile $*.pdf

holdouts: ## active-vs-random win, all moot sets, 10 cpus
	@ls $(MOOT)/*/*.csv | sort -R | xargs -n1 -P 10 sh -c \
	  'echo "$$(luajit lib.lua --DATA=$$(dirname $$1)/ \
	    --file=$$(basename $$1) --holdouts) $$1"' _
