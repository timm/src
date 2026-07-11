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
