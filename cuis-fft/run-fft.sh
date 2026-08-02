#!/bin/sh
# run-fft.sh -- run the Cuis port of fft.lisp, no window.
# Usage: ./run-fft.sh [egMain|egTrees|egGrows]
# Needs fft-cuis.image (make image). Runs headless: safe
# because classes are pre-baked; only fileIn/class creation
# hangs the headless Mac VM.
CUIS="${CUIS:-$HOME/Downloads/Cuis7-6-main}"
VM="$CUIS/CuisVM.app/Contents/MacOS/Squeak"
IMG="$CUIS/CuisImage/fft-cuis.image"
DEMO="${1:-egMain}"
exec "$VM" -headless "$IMG" \
  -d "FFT $DEMO" -d "Smalltalk quitPrimitive" 2>/dev/null
