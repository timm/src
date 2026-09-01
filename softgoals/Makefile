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
	@( echo " ,A,B (C),D,E (F),G,H (I),J,K,L,M,N"; echo " ,%d2h,%d2h,%d2h,%d2h,%d2h,%d2h,#,#,#,#,%"; echo "model,lo(b4),mu(b4),lo(all),mu(all),lo(keys),mu(keys),pool,shared,keys,tries,%keys"; \
	   for m in models/*.py small.py; do \
	     $(PY) run.py -seed $(S) $(FLAGS) $$m; done \
	 ) | column -s, -t

keys-lisp: ## same table via nfr7.lisp + rig7.lisp (truth walk)
	@$(PY) to-lisp.py >/dev/null
	@( echo " ,A,B (C),D,E (F),G,H (I),J,K,L,M,N"; echo " ,%d2h,%d2h,%d2h,%d2h,%d2h,%d2h,#,#,#,#,%"; echo "model,lo(b4),mu(b4),lo(all),mu(all),lo(keys),mu(keys),pool,shared,keys,tries,%keys"; \
	   for m in models/*.lisp small.lisp; do \
	     n=$$(basename $$m .lisp | sed 's/^CS//'); \
	     sbcl --script rig7.lisp $$m $$n 2>/dev/null | tail -1; done \
	 ) | column -s, -t

M ?= small.lisp

zoo: ## play every zoo model; make zoo S=3
	@sbcl --noinform --non-interactive --load nfr7.lisp \
	  --eval '(parade $(S))'

repl: ## lisp repl over the zoo: (play 'shop), (replay 'shop how)
	@rlwrap sbcl --noinform --load nfr7.lisp || \
	  sbcl --noinform --load nfr7.lisp

eg: ## paint one world for every model; make eg S=3
	@$(PY) to-lisp.py >/dev/null
	@sbcl --noinform --non-interactive --load nfr7.lisp \
	  --eval '(eg $(S))' 2>/dev/null

paint: ## make paint M=models/CSServices.lisp S=3 : model colored by one world
	@$(PY) to-lisp.py >/dev/null
	@sbcl --noinform --non-interactive --load nfr7.lisp \
	  --eval '(painted "$(M)" $(S))' 2>/dev/null
