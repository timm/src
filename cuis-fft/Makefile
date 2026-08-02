# cuis-fft -- fast frugal trees in five runtimes.
# make install   fetch + unpack Cuis if missing
# make image     bake FFT classes into fft-cuis.image
#                (one brief window flash; the Mac VM hangs
#                on class creation when -headless)
# make run       best tree, headless, no window
# make trees     all 16 trees
# make grows     timing demo
# make bench     full benchmark, all runtimes -> bench.out
# make clean     remove baked image

CUIS ?= $(HOME)/Downloads/Cuis7-6-main
ZIP  ?= $(HOME)/Downloads/Cuis7-6-main.zip
URL   = https://github.com/Cuis-Smalltalk/Cuis7-6/archive/refs/heads/main.zip
VM    = $(CUIS)/CuisVM.app/Contents/MacOS/Squeak
BASE  = $(CUIS)/CuisImage/Cuis7.6.image
IMG   = $(CUIS)/CuisImage/fft-cuis.image

run: $(IMG)
	CUIS=$(CUIS) ./run-fft.sh egMain

trees: $(IMG)
	CUIS=$(CUIS) ./run-fft.sh egTrees

grows: $(IMG)
	CUIS=$(CUIS) ./run-fft.sh egGrows

install: $(VM)

$(VM):
	@if [ -f "$(ZIP)" ]; then \
	  echo "unzip $(ZIP)"; \
	  unzip -q "$(ZIP)" -d "$(dir $(CUIS))"; \
	else \
	  echo "fetch $(URL)"; \
	  curl -sL "$(URL)" -o /tmp/cuis-fft.zip; \
	  unzip -q /tmp/cuis-fft.zip -d "$(dir $(CUIS))"; \
	fi
	@test -x "$(VM)" || { echo "install failed"; exit 1; }

image: $(IMG)

# NB: bake must run with cwd = Cuis dir; other cwds stall
# the VM on startup.
$(IMG): $(VM) fft.st
	rm -f "$(IMG)" "$(CUIS)/CuisImage/fft-cuis.changes"
	cd "$(CUIS)" && "$(VM)" "$(BASE)" -l "$(abspath fft.st)" \
	  -d "Smalltalk saveAndQuitAs: 'fft-cuis' clearAllClassState: false"

bench: $(IMG)
	CUIS=$(CUIS) ./bench.sh | tee bench.out

clean:
	rm -f "$(IMG)" "$(CUIS)/CuisImage/fft-cuis.changes" bench.out

.PHONY: run trees grows install image bench clean
