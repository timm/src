# rp0.py

{% raw %}
```text
rp0.py: step one of grid-from-table — incremental eps-cover.

Unsupervised leader clustering: warm up on the first the.warm rows
(sample pairs among them; eps = close * sd of those distances),
then stream every row: farther than eps from every delegate ->
found a new delegate; else fuse into the nearest delegate's kin.
No labels anywhere; the label bill, paid later, is one per
delegate. Demos: python3 rp0.py [--k v].
```

---

[----------------------------------------------------------- demos](#b1)

## ----------------------------------------------------------- demos {#b1}

<small>**----------------------------------------------------------- demos**</small>



```python
def test_cover():
  m = M(csv(the.file))
  D, kin, eps = cover(m)
  n = sum(len(v) for v in kin.values())
  print(f"  eps {eps:.3f}; rows {len(m.rows)} -> {len(D)} "
        f"delegates; kin conserve {n} rows")
  assert n == len(m.rows) and 1 <= len(D) < len(m.rows)

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(globals())
```

{% endraw %}