# m.py

{% raw %}
```text
m.py: M -- one-primitive row+column squeezer, on a label budget.

Rows in; labels counted; theory out (few rows x few cols + marks).
Norm is 10th/90th percentile lo-hi capped 0..1 (outliers saturate;
syms enum to 0..1). One SWEEP: pick ~anchors mutually-distant rows
(diverse, so twins never both labeled); weight every anchor pair by
d = dy/dx (labeled rounds) or dx (free rounds); mark each item with
sum over pairs of weight * |its projection - that view's median|;
cull marks below top/2 (anchors always survive). Transpose, sweep
columns the same way (always free), repeat till nothing shrinks;
then keep the cap best-marked rows and cols.

Findings (20 seeds x 10 moot datasets, win = normalized regret
complement, always vs random labeling at matched budget):
  labelled sweeps (~40 labels): win 100 on smooth sets, 75-83 rough;
  free sweeps + label survivors (~12): matches, except rough sets;
  free + label one per nearest pair (~6): usually beats random,
    loses where x-near rows are y-far (smoothness fails: LLVM);
  p sweep: labelled arm indifferent (p=2 a nudge better on the
    rough sets), so house p=2 stays; free arm swings per dataset
    (p=2 rescued X264's capped grid, 46->100; p=1 better SS-O/I).

Demos: python3 m.py [--k v].  (c) 2026 Tim Menzies, MIT license.
```

---

[----------------------------------------------------------- demos](#b1)

## ----------------------------------------------------------- demos {#b1}

<small>**----------------------------------------------------------- demos**</small>



```python
def test_m():
  m = M(csv(the.file))
  print("  m:", len(m.rows), "rows,", len(m.x), "x cols")
  assert len(m.rows) == 398 and len(m.x) == 5

def test_labelled():
  m = M(csv(the.file))
  R, C, spent, ys = squeeze(m)
  print(f"  {len(m.rows)}x{len(m.x)} -> {len(R)}x{len(C)}; "
        f"labels {spent}; best lbl {min(ys.values()):.2f}")
  assert spent <= the.budget and 2 <= len(R) <= the.cap

def test_free():
  m = M(csv(the.file))
  R, C, spent, _ = squeeze(m, labelled=False)
  best = min(disty(m, i) for i in R)             # cash out: label R
  print(f"  {len(m.rows)}x{len(m.x)} -> {len(R)}x{len(C)}; "
        f"labels 0 (+{len(R)} to cash); best alive {best:.2f}")
  assert spent == 0 and 2 <= len(R) <= the.cap

def cli(d, s):
  for k, old in vars(d).items():
    if mm := re.search(f"--{k}[= ]+(\\S+)", s):
      vars(d)[k] = type(old)(mm.group(1))

def tests(funs):
  for k, f in sorted(funs.items()):
    if k[:5] == "test_": print("#", k); srand(the.seed); f()
  print("all passed")

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(globals())
```

{% endraw %}