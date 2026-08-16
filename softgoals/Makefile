# vim: ts=8 noexpandtab :
SHELL := /bin/bash
.DEFAULT_GOAL := help
ETC := $(realpath ..)/etc

help: ## show targets
	@grep -hE '^[a-z-]+:.*## ' Makefile | \
	  awk -F':.*## ' '{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

sh: ## bash tuned by ../etc/bashrc
	@here="$(CURDIR)" bash --rcfile $(ETC)/bashrc -i

S ?= 1
PY ?= python3

keys: ## REPORT_keys table; make keys S=3 FLAGS="-n1 256"
	@( echo "dataset,mu,sd,best,muSeed,sdSeed,n_filt,seed,tests,pct"; \
	   for m in models/*.py small.py; do \
	     ./keys.py -seed $(S) $(FLAGS) $$m; done \
	 ) | column -s, -t
