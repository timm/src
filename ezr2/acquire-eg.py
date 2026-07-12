"""
## The active learner

`acquire` spends the label budget (default 50): label a
few rows, project the rest onto the line joining two far
labelled poles, cull the third nearest the bad pole,
repeat. Two studies: per-run active vs random deltas on a
bigger table, then one mean-win summary line.

| call | returns | what |
|------|---------|------|
| `acquire(data)` | rows | labelled few, best first |
"""

def test_acquire():
  "20 shuffles; active vs random, sorted by significant delta."
  f0 = the.file
  the.file = "$MOOT/optimize/binary_config/billing10k.csv"
  data = Data(csv(the.file))
  data.rows = some(data.rows, the.cap)
  A, R = [], []
  for i in range(20):
    random.seed(the.seed + i)
    data.rows = shuffle(data.rows)
    the.acquire = "active"
    A += [disty(data, acquire(data)[0])]
    the.acquire = "random"
    R += [disty(data, acquire(data)[0])]
  the.acquire = "active"
  sd_ = lambda z: (sum((v - sum(z)/len(z))**2
                       for v in z) / (len(z)-1)) ** 0.5
  pooled = (((len(A)-1)*sd_(A)**2 + (len(R)-1)*sd_(R)**2)
            / (len(A)+len(R)-2)) ** 0.5
  thr = 0.35 * pooled  # tie below small effect; +ve => active
  out = [(a, r, (r-a if abs(r-a) >= thr else 0.0))
         for a, r in zip(A, R)]
  up = chr(0x25B2)     # marks whichever side won this run
  print("rank  aDisty  rDisty   delta  win  (%s)"
        % the.file.split("/")[-1])
  for k,(a,r,d) in enumerate(sorted(out, key=lambda t:-t[2])):
    win = ("tie" if d == 0 else
           "%s active" % up if d > 0 else "%s random" % up)
    print("%4d %7.3f %7.3f  %+6.3f  %s" % (k, a, r, d, win))
  win  = sum(d for _,_,d in out if d > 0)
  loss = -sum(d for _,_,d in out if d < 0)
  the.file = f0
  assert win > loss  # size of wins beats size of losses

def test_acquires():
  "One summary line: mean win/disty over 20 runs."
  data = Data(csv(the.file))
  data.rows = some(data.rows, the.cap)
  W, ds, ws, n = wins(data), [], [], 0
  for i in range(20):
    random.seed(the.seed + i)
    data.rows = shuffle(data.rows)
    got = acquire(data)
    ds += [disty(data,got[0])]; ws += [W(got[0])]; n = len(got)
  print("%6.1f %7.3f %4d  %s" % (sum(ws)/len(ws),
        sum(ds)/len(ds), n, the.file.split("/")[-1]))
  assert -100 <= sum(ws)/len(ws) <= 100
