"""
## Label a few, explain with a tree

`landscape` spends the label budget; `tree` then recurses
min-cost cuts over just those labelled rows, and `show`
prints it -- win (100=best, 0=median), n, per-goal means,
then the branch conditions:

       win     n      Lbs-     Acc+     Mpg+
         3    44  2520.545   16.609   28.182
        41    21  2017.762   16.914   31.905  Volume <= 108
    ▲   83     3  1924.000   20.333   30.000  |  Model <= 73

Notice: ~44 labels, and the ▲ best leaf reads as advice --
small engine, early model.

| call | returns | what |
|------|---------|------|
| `tree(data, rows)` | node | recurse min-cost cuts |
| `leaf(data, t, row)` | value | route row to its leaf |
"""

def test_tree():
  "Build a tree over landscape's rows and print it."
  random.seed(the.seed)
  data = Data(csv(the.file))
  data.rows = some(data.rows, the.cap)
  show(data, tree(data, landscape(data)))
