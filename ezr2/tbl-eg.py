"""
## The whole table

`Tbl` streams the csv once: the first row names the
columns and `Cols` types them from the name suffixes;
later rows update the per-column summaries. Notice auto93's
shape: 4 x-columns, 3 goals (minimize Lbs-, maximize Acc+
and Mpg+), one ignored column (HpX).

| call | returns | what |
|------|---------|------|
| `Tbl(csv(f))` | tbl | rows + column summaries |
| `clone(tbl, rows)` | tbl | fresh table, same header |
"""

def test_data():
  "Tbl build: col Cols and goal stats."
  tbl = Tbl(csv(the.file))
  print("rows %s |x| %s |y| %s" % (len(tbl.rows),
        len(tbl.x), len(tbl.y)))
  if "auto93" in the.file:
    assert len(tbl.rows) == 398
    assert len(tbl.x) == 4 and len(tbl.y) == 3
    mpg = tbl.cols[tbl.y[-1]]
    print("Mpg+ mu %.2f sd %.2f" % (mu_(mpg), sd(mpg)))
    assert abs(mu_(mpg) - 23.84) < 0.1
    assert abs(sd(mpg) - 8.34) < 0.1
