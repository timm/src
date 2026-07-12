# Column summaries. `Num` is a (n,mu,m2) tuple grown by
# `welford`; `Sym` is a dict of counts. `mid`/`var` =
# centrality and dispersion for either; `mix` merges two
# summaries (inc=-1 subtracts); `pick` samples one value
# (roulette or Irwin-Hall bell).

Sym = dict
def is_sym(i): return isinstance(i, dict)  # Sym = dict of counts
def Num(n=0, mu=0, m2=0): return (n, mu, m2)

def n_(num)  : return num[0]
def mu_(num) : return num[1]
def m2_(num) : return num[2]

def mid(i): return max(i,key=i.get) if is_sym(i) else mu_(i)
def var(i): return entropy(i)       if is_sym(i) else sd(i)

def sd(num): n,_,m2=num;return 0 if n<2 else(max(0,m2)/(n-1))**.5

# Shannon entropy of a Sym (a dict of counts)
def entropy(d):
  N = sum(d.values()) or 1
  return -sum(v/N*log2(v/N) for v in d.values() if v)

# Change or delete keys
def count(sym,v,inc=1):
  if (c := sym.get(v,0) + inc) > 0: sym[v] = c
  else: sym.pop(v, None)
  return sym

# Fold v into a Num (inc=-1 removes); return new (n,mu,m2)
def welford(num, v, inc=1):
  n, mu, m2 = num
  if (n := n + inc) <= 0: return Num()
  d = v - mu; mu += inc * d / n
  return (n, mu, m2 + inc * d * (v - mu))

# Merge two cols; inc=-1 subtracts j from i
def mix(i, j, inc=1):
  if is_sym(i):
    return {k: i.get(k, 0) + inc * j.get(k, 0) for k in i | j}
  (ni, mui, m2i), (nj, muj, m2j) = i, j
  n = ni + inc * nj
  if n <= 0: return Num()
  d  = muj - mui
  mu = (ni * mui + inc * nj * muj) / n
  m2 = m2i + inc * m2j + inc * d * d * ni * nj / n
  return Num(n, mu, max(0, m2))  # subtraction can underflow m2

# Sample one value: roulette for a Sym, Irwin-Hall for a Num
def pick(col, v=None):
  if is_sym(col):                  # roulette wheel over counts
    n = sum(col.values()) * random.random()
    for k, c in col.items():
      if (n := n - c) <= 0: return k
    return k
  mu = mu_(col) if v is None or v == "?" else v  # bell at v|mu
  r  = random.random
  return mu + sd(col)*2*(r()+r()+r()-1.5)
