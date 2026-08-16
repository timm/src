# small.py : buy-vs-build, in the algebra dialect.
from nfr5 import *

(built,deployed,buy,diy,vendor,coders,tested,usable,
 cheap,fast,private,cloud,onprem) = atoms(
  "built deployed buy diy vendor coders tested usable "
  "cheap fast private cloud onprem")

built    <= buy + diy
buy      <= vendor * breaks(cheap) * helps(fast)
diy      <= coders * helps(cheap) * hurts(fast)
deployed <= cloud + onprem
cloud    <= helps(fast) * hurts(private)
onprem   <= makes(private) * hurts(fast)
usable   <= tested * helps(fast)

HARD = [built, deployed]
SOFT = cheap + fast + private

if __name__ == '__main__':
    import random; from nfr5 import sample
    random.seed(1)
    Q = [g for h in HARD for g in (h,(h,'t'))] + [SOFT]
    for _ in range(4): print(sample(Q))
    print('seeded diy:', sample(Q, {diy:'t'}, replay=True))
