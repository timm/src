# vim: ts=8 noexpandtab :
# pdf: 5.5 = biggest font with no wrap at 65 chars + line
# numbers; sections break clean at 74-line columns. NB: no
# inline comments here: they leave trailing blanks in the
# value, and awk then compares C as a string, not a number.
Font = 5.5
LPC  = 74
include ../../Makefile

POOL ?= $(HOME)/gits/moot/optimize

# NB: no literal "#" in HIST: in a make variable (unlike a
# recipe) "#" starts a comment. char 35 builds the bar.
HIST = sort -n | awk '{a[NR]=$$1} \
	   END{for(d=1; d<=10; d++){ \
	     lo=int((d-1)*NR/10)+1; hi=int(d*NR/10); s=0; \
	     for(i=lo; i<=hi; i++) s+=a[i]; \
	     m=(hi>=lo) ? s/(hi-lo+1) : 0; b=""; \
	     while(length(b) < int(m+0.5)) b=b sprintf("%c",35); \
	     printf "%3d%% %5.1f %s\n", d*10, m, b}}'

loclua: ## lua function size deciles (mean LOC)
	@awk 'FNR==1       {if (f) print n; f=""} \
	      /^function / {if (f) print n; f=$$2; n=0} \
	      f && NF      {n++} \
	      END          {if (f) print n}' *.lua | $(HIST)

lint: ## luacheck all lua sources
	luacheck *.lua; true

%.pdf: ## file in this dir -> pdf, via the root rule
	@cd .. && $(MAKE) -f ../Makefile \
	   Font=$(Font) LPC=$(LPC) Cols=$(Cols) $*.pdf

holdouts: ## active-vs-random win, all moot sets, 10 cpus
	@mkdir -p ~/tmp
	@ls $(POOL)/*/*.csv | sort -R | xargs -n1 -P 10 sh -c \
	  'echo "$$(luajit ezr3-eg.lua --DATA=$$(dirname $$1)/ \
	    --file=$$(basename $$1) --holdouts) $$1"' _ \
	  | tee ~/tmp/holdouts.log
	@echo; awk '{print int($$2+0.5)}' ~/tmp/holdouts.log | \
	  sort -n | awk '{printf "%4d", $$1; \
	    if (NR%16==0) print ""} END{if (NR%16) print ""}'
