# rpl2.py

{% raw %}
```text
rpl2.py: M — the one-primitive squeezer. Rows in, labels counted.
Norm = 10th/90th percentile lo-hi, capped 0..1 (outliers saturate;
syms enum to 0..1). One sweep: ~10 mutually-distant anchors (labeled,
on row passes), all anchor pairs weighted d = dy/dx (rows) or dx
(cols); every item marked with sum over pairs of weight * |its
projection - that view's median|; cull marks under half the top.
Transpose, sweep again, repeat till nothing shrinks or budget dies.
Demos: python3 rpl2.py [--k v].
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

def test_squeeze2():
  m = M(csv(the.file))
  R, C, spent, ys = squeeze(m)
  best = min(ys.values())
  pool = min(disty(m, i) for i in range(len(m.rows)))
  print(f"  rows {len(m.rows)} -> {len(R)}; cols {len(m.x)} -> "
        f"{len(C)}; labels {spent}; best lbl {best:.2f} "
        f"(pool {pool:.2f})")
  assert spent <= the.budget and 2 <= len(R)

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  rpl1.the.seed = the.seed
  tests(globals())
```

{% endraw %}