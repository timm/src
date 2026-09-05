{% raw %}
# Why walk() never descends both sides ("no 3")

**tl;dr** A depth-d regression tree implies a space of
pruned trees where, below each cut, each side either exits
as a leaf or descends. Enumerating all four per-cut policies
(0=bothLeaves, 1=worstLeaf, 2=bestLeaf, 3=noLeafs) grows
doubly-exponentially; policy 3 won 0 of 1270 races over the
whole corpus. Dropping it caps the pool at 2^d - 1 trees,
makes d=8 cost 0.04s instead of being impossible, and the
result still ties full-tree ezr on 127/127 datasets.

## Rig

All studies: `$MOOT/optimize/*/*.csv` corpus (127 files,
capped at 1024 rows), 50:50 shuffle split, sway3 active
labelling at budget B picks the training labels, a depth-4
regression tree (leaf 3) fits their `disty`, the model
ranks the unseen half, the best of the top 5 test rows is
bought. Score = `wins` (100 = best row, 0 = median).
Arms are paired (repeat k reseeds every arm with seed+k);
deltas count 0 unless `same()` (Cohen + Cliff's + KS) can
tell the two win-distributions apart. `race` selects among
prunings by the mean ACTUAL disty of the rows a tree routes
to its best-predicted leaf -- the deployment criterion --
not by regression error over all leaves.

## 1. The full pruning space explodes

With all four policies the count is
V(cut) = (1 + V(yes)) * (1 + V(no)):

    d :      2   3    4        5        6
    V :      4  25  676  458,329  2.1e11

4^d is a flattering underestimate. d=5 is already marginal;
d=6 cannot even be enumerated.

## 2. Labels matter more than tree shape

20 repeats x 25 random datasets. fft trained on ALL ~512
train rows beat active@50 8 wins to 1 (16 ties) -- but give
both arms the same budget of RANDOM labels and fft loses to
active 1:8 at B=50. Racing prunings cannot rescue bad
labels; sway3's choices are the signal.

## 3. Same labels, raced pruning == full tree

Both arms fed the identical sway3 labels (B in 50,100,200),
fft races the prunings, ezr keeps the full tree:
73 ties, 1 loss, 0 wins over 75 cells. Tree shape is a
free choice; take the small one.

## 4. What wins the race: worst-exit spines

1270 raced winners (127 datasets x 10 repeats, B=50),
policy string = one digit per level:

     703 1110      248 110      157 10      74 0
      25 1210       21 1120     11 20      10 210
       9 120         9 2110      3 1220

93% are pure worst-leaf spines (`1...10`); `1110` alone is
55%. Policy 2 appears in 7%, at most once per tree.
**Policy 3 appears 0 times in 1270 trees.**

## 5. Depth can shrink too

fft@50 at maxd=d vs active@50 (maxd 4), 20 x 25:

    d=1  0W 14L 11T   median 71.0
    d=2  0W  7L 18T   median 74.0
    d=3  0W  3L 22T   median 77.0
    d=4  0W  0L 25T   median 76.3   (active: 76.4)

Three cuts read in one breath and tie the full tree on 22
of 25 datasets.

## 6. Speed: no-3 turns deep trees from impossible to free

Whole-train (512 rows, SS-N), walk + race:

    d=4   full  416 trees 0.22s    no-3 14 trees 0.01s
    d=5   full  17,169    9.6s     no-3 24       0.01s
    d=6   full  3.8e6     --       no-3 39       0.02s
    d=8   full  1.1e14    --       no-3 86       0.04s

At B=50 the saving is invisible (sway3's distance
projections are 85-90% of runtime), but no-3 is what makes
d > 4 feasible at all.

## 7. Head to head

tiny (sway3@50 labels, no-3 walk, best-leaf race) vs normal
ezr (same labels, full depth-4 tree), 20 paired repeats,
all 127 datasets:

    tiny wins 0   losses 0   ties 127
    median mu(win): tiny 86.1   ezr 86.8

Not one dataset where `same()` can tell them apart.

## 8. Depth can grow too: 6+ wins on config landscapes

Section 5 swept d DOWN from 4; section 6 showed no-3 makes
d > 4 affordable. Does anything up there win? Same rig
(whole corpus, now 128 files; 20 paired repeats, B=50,
same sway3 labels per repeat feeding every arm), arms =
maxd 4, 6, 8, race as usual (depth6.py):

    maxd=6 vs 4:  18W  1L  109T   max +7.6  min -7.8
    maxd=8 vs 4:  18W  0L  110T   max +10.8

Median mu(win) 86.3 / 87.3 / 87.3; mean pool 8 -> 11
trees; the whole 128 x 20 x 3 sweep runs in 80s.

Actual depth of the 2560 raced winners per arm:

    maxd=4:  1:6%  2:13%  3:22%  4:59%
    maxd=6:  1:6%  2:12%  3:21%  4:26%  5:22%  6:13%
    maxd=8:  1:6%  2:12%  3:20%  4:26%  5:21%  6:10%  7:4%  8:1%

Given room, 35% of winners pass depth 4 -- the 59% mass at
4 was partly ceiling -- though 7-8 stays rare (5%) even
when free. The 18 winning datasets are configuration
landscapes: SS-A/D/E/F/G/I/K/P, javagc, X264, FM-500-SAT,
HSMGP, Scrum1k, plus all_players, socks, Health-*. Largest
gains SS-G +10.8 and SS-F +9.9 at maxd=8. The one maxd=6
loss (Health-ClosedIssues0001, -7.8) vanishes at maxd=8.
So no-3's cheap deep trees are not just a speed trick:
maxd=8 costs nothing anywhere and buys real wins on ~14%
of the corpus.

## 9. Winner shapes at maxd=6: still a few conditions

Policy strings of the 2560 maxd=6 winners (winners.py;
digit per level, trailing 0 = the fallback cut, so
`1110` = 3 conditions then fall back):

    600 1110      492 110       465 11110     304 10
    262 111110    154 0          33 1210       28 11210
     26 1120       25 12110      20 11120      20 120
     17 111210     16 112110     16 20         14 210
     13 2110       12 111120     10 121110      8 21110
      5 12210      4 1220         4 211110      3 112210
      2 121210     2 12120     + 5 seen once

Worst-exit spines still rule: pure `1..10` plus `0` = 89%
(93% at maxd=4); policy 2 in 11% of trees, almost always
once. `1110` stays modal but drops 55% -> 23%; its mass
moves up to `11110` (18%) and `111110` (10%).

Conditions asked before fallback, maxd=4 (from the 1270
winners of section 4) vs maxd=6, both sum to 100%:

    levels:            distinct attributes:
    n   maxd4  maxd6   n   maxd4  maxd6
    0     6%     6%    0     6%     6%
    1    13%    13%    1    17%    16%
    2    21%    21%    2    36%    29%
    3    60%    26%    3    41%    30%
    4     -     22%    4     -     15%
    5     -     13%    5     -      5%

At maxd=4, 60% of winners sat at the depth ceiling; freed
to 6, that mass spreads (only 13% now pin at the new
ceiling) and levels split from attributes: 5-6 cut spines
reuse attributes, so the median winner still interrogates
just 3 distinct attributes, 80% need <= 3, 95% <= 4. The
"few conditions usually do" claim survives depth 6; the
floor just moves from "2-3 attributes" to "3, rarely 4+".

## Moral

Policy 3 never wins and is the sole reason the pruning pool
explodes. So `walk` does not generate it: below every cut,
both sides exit, or exactly one descends. Cost: nothing,
on 127 datasets. Benefit: a 2^d - 1 pool, sub-0.1s races at
any depth, and winning models that are 3-4 line
fast-and-frugal spines instead of 15-cut trees.

{% endraw %}