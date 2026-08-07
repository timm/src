# usage:
#   make ssm.txt                 # csv in current dir
#   make SS-A.txt                # csv found anywhere under MOOT
#   make ssm.txt D=/other/path   # csv in some other dir
#
# pipeline:  x.csv --bin--> x_b.csv --run--> x.txt --report--> stdout

MOOT ?= $(HOME)/gits/timm/moot
D    ?= .
BINS ?= 6
K    ?= 3
FAR  ?= 6
P    ?= .1
SEED ?= 1

vpath %.csv $(D) $(shell find $(MOOT) -type d 2>/dev/null | tr '\n' ' ')

.PRECIOUS: %_b.csv

%.txt: %.csv
	python3 rp.py bin $< $(BINS) > $*_b.csv
	python3 rp.py run $*_b.csv $(K) $(FAR) $(P) $(SEED) > $@
	python3 rp.py report < $@
