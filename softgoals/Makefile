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
	     $(PY) run.py -seed $(S) $(FLAGS) $$m; done \
	 ) | column -s, -t

keys-lisp: ## same table via nfr5.lisp + rig.lisp (park-miller rng)
	@$(PY) to-lisp.py >/dev/null
	@( echo "dataset,mu,sd,best,muSeed,sdSeed,n_filt,seed,tests,pct"; \
	   for m in models/*.lisp small.lisp; do \
	     n=$$(basename $$m .lisp | sed 's/^CS//'); \
	     sbcl --script rig.lisp $$m $$n 2>/dev/null | tail -1; done \
	 ) | column -s, -t

M ?= small.lisp

paint: ## make paint M=models/CSServices.lisp S=3 : model colored by one world
	@$(PY) to-lisp.py >/dev/null
	@sbcl --script paint.lisp $(M) $(S) 2>/dev/null
