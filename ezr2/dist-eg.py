"""
## Distance to heaven

`disty` scores each row by distance to the ideal goals
(0 = best), reading only the y columns. Sort our table by
it and the best cars float to the top:

    Clndrs  Volume  HpX  Model  origin  Lbs-  Acc+  Mpg+  disty
         4      90   48     78       2  1985  21.5    40  0.075
         4      90   48     80       2  2085  21.7    40  0.087
         4      85   65     81       3  1975  19.4    40  0.087

         8     440  215     70       1  4312   8.5    10  0.956
         8     455  225     73       1  4951    11    10  0.956

Notice the shape: light, late, high-mpg cars up top; big
old guzzlers at the bottom.

| call | returns | what |
|------|---------|------|
| `disty(tbl, row)` | 0..1 | distance to ideal goals |
| `distx(tbl, r1, r2)` | 0..1 | difference over x cols |
"""

def test_disty():
  "Rows sorted by disty: header, top 5, blank, bottom 5."
  tbl = Tbl(csv(the.file))
  rows = sorted(tbl.rows, key=lambda r: disty(tbl, r))
  hdr  = list(tbl.names) + ["disty"]
  fmt  = lambda r: [str(v) for v in r]+["%.3f" % disty(tbl,r)]
  body = [fmt(r) for r in rows[:5] + rows[-5:]]
  w = [max(len(row[c]) for row in [hdr]+body)
       for c in range(len(hdr))]
  line = lambda cs: print("  ".join(c.rjust(w[i])
                                    for i,c in enumerate(cs)))
  line(hdr)
  for r in body[:5]: line(r)
  print()
  for r in body[5:]: line(r)
  assert disty(tbl, rows[0]) <= disty(tbl, rows[-1])
