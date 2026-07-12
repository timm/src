"""
## The whole table

`Data` streams the csv once: the first row names the
columns and `roles` types them from the name suffixes;
later rows update the per-column summaries. Notice auto93's
shape: 4 x-columns, 3 goals (minimize Lbs-, maximize Acc+
and Mpg+), one ignored column (HpX).

| call | returns | what |
|------|---------|------|
| `Data(csv(f))` | data | rows + column summaries |
| `clone(data, rows)` | data | fresh table, same header |
"""

def test_data():
  "Data build: col roles and goal stats."
  data = Data(csv(the.file))
  print("rows %s |x| %s |y| %s" % (len(data.rows),
        len(data.x), len(data.y)))
  if "auto93" in the.file:
    assert len(data.rows) == 398
    assert len(data.x) == 4 and len(data.y) == 3
    mpg = data.cols[data.y[-1]]
    print("Mpg+ mu %.2f sd %.2f" % (mu_(mpg), sd(mpg)))
    assert abs(mu_(mpg) - 23.84) < 0.1
    assert abs(sd(mpg) - 8.34) < 0.1
