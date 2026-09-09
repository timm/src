# cells.py

{% raw %}
```text
cells.py: repgrid squeeze at CELL granularity (timm 2026-08-08).

Label the.picks random rows (one round: bingo effect — discretized
columns hold few patterns, so 30 rows cover them). Cell values come
from m.py's norm: saturate past the f/1-f percentiles, so outliers
just score 0 or 1. Every scored cell earns three 0..1 terms:
(1-y) of its row, its row's mean Chebyshev gap to the other picks,
its col's mean Chebyshev gap to the other live cols (all gaps over
the picks only — never O(n^2)). Dump the bottom half of scored
cells; a row or col dies on losing more than half its cells. Rows
never picked carry no evidence: they survive by default, but the
emitted grid draws from the evidenced picks.
Demos: python3 cells.py [--k v].
```

---

[----------------------------------------------------------- demos](#b1)

## ----------------------------------------------------------- demos {#b1}

<small>**----------------------------------------------------------- demos**</small>



```python
def test_cells():
  m = M(csv(the.file))
  R, C, S, y, _ = cells(m)
  best = min(y[i] for i in R) if R else 1
  print(f"  picks {len(S)} (=labels); grid {len(R)} x {len(C)}; "
        f"best pick {min(y.values()):.2f}, best survivor {best:.2f}")
  assert len(R) <= len(S) and 1 <= len(C) <= len(m.x)

def test_holdout():
  m = M(csv(the.file))
  R, C, S, y, _ = cells(m)
  best5, top = holdout(m, R, C, y)
  d = disty(m, best5[0])
  print(f"  {len(y)}+{len(top)} labels; best of top-5 d2h {d:.2f}; "
        f"best pick was {min(y.values()):.2f}")
  assert len(best5) == 5

if __name__ == "__main__":
  cli(the, " ".join(sys.argv[1:]))
  tests(globals())
```

{% endraw %}