#!/bin/sh
# bench.sh -- benchmark all fft ports: startup, small task,
# big run (2000 reps x sample 100), wall time + peak RSS.
# Run from this directory (fft.lisp loads lithp.lisp by cwd).
# Skips any runtime not installed.
cd "$(dirname "$0")" || exit 1
CUIS="${CUIS:-$HOME/Downloads/Cuis7-6-main}"
VM="$CUIS/CuisVM.app/Contents/MacOS/Squeak"
IMG="$CUIS/CuisImage/fft-cuis.image"
REPS="${REPS:-2000}"

t() { # t label cmd...
  L="$1"; shift
  echo "-- $L"
  /usr/bin/time -l "$@" 2>&1 >/dev/null | \
    grep -E "real|maximum resident" | sed 's/^ *//'
}
o() { # o label cmd...  (keep stdout last line too)
  L="$1"; shift
  echo "-- $L"
  OUT=$(/usr/bin/time -l "$@" 2>/tmp/bench.$$; true)
  echo "$OUT" | tail -1
  grep -E "real|maximum resident" /tmp/bench.$$ | sed 's/^ *//'
  rm -f /tmp/bench.$$
}

echo "== startup only (start + quit) =="
command -v lua     >/dev/null && t "lua"     lua -e ""
command -v luajit  >/dev/null && t "luajit"  luajit -e ""
command -v python3 >/dev/null && t "python3" python3 -c ""
command -v sbcl    >/dev/null && t "sbcl"    sbcl --script /dev/null
[ -x "$VM" ] && t "cuis" "$VM" -headless "$IMG" -d "Smalltalk quitPrimitive"

echo; echo "== small task: egMain (one tree, full data) =="
command -v lua     >/dev/null && t "lua"     lua fft.lua
command -v luajit  >/dev/null && t "luajit"  luajit fft.lua
command -v python3 >/dev/null && t "python3" python3 fft.py
command -v sbcl    >/dev/null && t "sbcl"    sbcl --script fft.lisp
[ -x "$VM" ] && t "cuis" "$VM" -headless "$IMG" \
  -d "FFT egMain" -d "Smalltalk quitPrimitive"

echo; echo "== big run: egGrows $REPS reps, sample 100 =="
command -v lua     >/dev/null && o "lua"     lua fft.lua --grows "$REPS" 100
command -v luajit  >/dev/null && o "luajit"  luajit fft.lua --grows "$REPS" 100
command -v python3 >/dev/null && o "python3" python3 fft.py --grows "$REPS" 100
command -v sbcl    >/dev/null && o "sbcl (includes one stray egMain from load)" \
  sbcl --noinform --non-interactive --load fft.lisp \
  --eval "(eg-grows $REPS 100)"
[ -x "$VM" ] && o "cuis" "$VM" -headless "$IMG" \
  -d "FFT egGrows: $REPS sample: 100" -d "Smalltalk quitPrimitive"

echo; echo "== source size =="
wc -l -c fft.lua fft.py fft.st fft.lisp lithp.lisp
