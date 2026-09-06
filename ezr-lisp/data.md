## 1. Data

Header names carry the whole schema: leading uppercase means
numeric; a trailing `+` or `-` marks a goal; trailing `X` says
ignore me.

```py
def Num(): return (0, 0, 0, 0)  # n, mu, m2, sd
Sym = dict
```

<p class="card"><b class="q">Why tuples?</b><br>
Immutable stats compose: <code>add</code> returns a fresh
accumulator, <code>sub</code> gives complements for free.</p>
