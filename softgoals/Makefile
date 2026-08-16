# vim: ts=8 noexpandtab :
SHELL := /bin/bash
.DEFAULT_GOAL := help
ETC := $(realpath ..)/etc

help: ## show targets
	@grep -hE '^[a-z-]+:.*## ' Makefile | \
	  awk -F':.*## ' '{printf "  \033[36m%-8s\033[0m %s\n", $$1, $$2}'

sh: ## bash tuned by ../etc/bashrc
	@here="$(CURDIR)" bash --rcfile $(ETC)/bashrc -i

tiny: ## run tiny.pl demo (figs 3,5,6 slice)
	@swipl -g 'row(X,Y), print(X-Y), nl, halt' -g 'halt(1)' tiny.pl

MODELS := CSCounselling CSCounsellingManagement CSFDandMarketing \
          CSITDepartment CSSAProgram CSServices KidsandYouth

keys: ## REPORT_keys table (prolog gen18.pl, all models)
	@( echo "dataset,mu,sd,best,muSeed,sdSeed,n_filt,seed,tests,pct,gen_ms,dd_ms,as_ms"; \
	   for m in $(MODELS); do \
	     swipl -g "run('models/$$m.pl')" -g halt gen18.pl 2>/dev/null; \
	   done ) | column -s, -t

pykeys: ## same table via python keys.py (small only, for now)
	@( echo "dataset,mu,sd,best,muSeed,sdSeed,n_filt,seed,tests,pct"; \
	   ./keys.py small.py ) | column -s, -t
