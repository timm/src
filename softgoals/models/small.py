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
