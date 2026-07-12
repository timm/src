# Main. `holdout` is the evaluation rig: label half the
# tbl via `acquire`, grow a tree, let it rank the unseen
# half, check only the top few rows, return the best found.
# `main` maps --key=val flags onto `the`, then runs any
# test_* named on the command line (from the caller's
# globals -- the eg files register nothing).

# Budget rig: acquire train -> tree -> pick best test row
def holdout(tbl):
  rows  = shuffle(tbl.rows)
  half  = len(rows)//2
  train, test = rows[:half], rows[half:]
  got   = acquire(clone(tbl, train))
  t     = tree(tbl, got)
  top   = sorted(test, key=lambda r: leaf(tbl,t,r))[:the.check]
  return min(top, key=lambda r: disty(tbl,r))

# Apply --key=val to `the`, then run named test_* in `funs`
def main(funs):
  if "-h" in sys.argv: return print(__doc__)
  for a in sys.argv[1:]:
    if a[:2]=="--" and "=" in a:
      k,v = a[2:].split("=",1)
      if k in vars(the): setattr(the, k, thing(v))
  for a in sys.argv[1:]:
    if (n := "test_"+a) in funs:
      random.seed(the.seed); funs[n]()
