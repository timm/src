# shortr1 vs shortr2

shortr1 = the SHORT paper's own engine (arXiv:1702.05568, Mathew,
Menzies, Ernst & Klein; repo github.com/dr-bigfatnoob/softgoals,
resolved from the paper's goo.gl/gvxeaH link; python, backward
chaining + differential evolution).  shortr2 = this directory's
engine (nfr6.lisp: forward ISAMP world sampler, unified walk,
rig6.lisp pipeline).  Same eight community-service i* models.

Reproduce: shortr1 clone in ~/tmp/shortr1 (py2->py3 shim: iteritems,
xrange, unicode, decode identity -- patched in the clone only);
driver script scratchpad/shortr1_table.py runs OUR pipeline shape
(b4 / replay-all / replay-keys, pool/shared/keys, ddmin) on THEIR
engine.  shortr2 numbers: `sbcl --script rig6.lisp MODEL NAME`.

## Are the models the same?

Yes.  Node counts match our reconstructions exactly where the paper
reports them: Services 351, Counselling 350, CnslMgmt 206,
ITDepartment 126 (paper's "300" memories are the edge counts).
Small deltas (Kids 79 vs 81, Modernize 51 vs 53) are isolated
legend/orphan nodes our port dropped.

## Engine differences, in one table

|                  | shortr1                        | shortr2 (nfr6) |
|------------------|--------------------------------|----------------|
| direction        | backward, from root goals      | forward, from a gated query |
| one candidate    | leaf coin-toss + derived rest  | one ISAMP world (labelling) |
| truth values     | four (t, t/2, f/2, f)          | two (t, f) |
| hard goals       | counted (roots covered)        | gated: underivable = dead world |
| constraints      | none; nothing is illegal       | demands (=) kill worlds |
| contributions    | FIRST positive contributor wins| dice vs bag, veto by prior labels |
| cycles           | random value; goals get t FREE | memo t, undo + denial on failure |
| decisions        | leaves only, by construction   | leaves + (optionally) or-heads |
| replay           | none (fix leaves, rerun)       | same walk + preloaded labels; claims re-earn |
| search           | DE / NSGA-II / GALE            | sample-and-select + ddmin |
| explanation      | ranked decisions (~12%)        | 1-minimal keys + provenance test |

## Apples to apples

Protocol: 1000 untreated runs (b4), take the best, replay its full
decision set 30x (all), ddmin to keys, replay keys 30x.  Metric for
shortr1 = % root goals covered (higher better; their score).  Metric
for shortr2 = %d2h (lower better; benefit vs cost -- shortr1 has no
cost in its score, so columns are same-shaped, not same-unit).

shortr1 (python3, seed 1):

    model         hi(b4) mu(b4)  hi(all) mu(all) hi(keys) mu(keys) pool shared keys tries  ms
    Counselling     97   79 (7)    97    97 (0)    97     92 (2)   100    5      7   628   46423
    CnslMgmt        95   78 (7)    95    95 (0)    95     89 (3)    70   10      7   123    9928
    FDandMarketing  95   81 (5)    95    94 (1)    93     86 (5)    99    7     13   178   42393
    ITDepartment   100   83 (13)  100   100 (0)   100     94 (3)    36    9      5   135    6030
    SAProgram      100   87 (6)   100   100 (0)   100     98 (3)    16    2      3    48    2576
    Services        78   58 (7)    78    78 (0)    81     72 (5)    71    7     20   231   98300
    KidsandYouth    96   68 (8)    96    92 (3)   100     87 (6)    28    3     16    91    1986

shortr2 (nfr6 unified walk, heads in candidates, lisp, seed 1):

    model         lo(b4) mu(b4)  lo(all) mu(all)  lo(keys) mu(keys) pool shared keys tries  ms
    Counselling      7   67 (21)  141   219 (50)    28     70 (18)   97   61     1*    6     49
    CnslMgmt         0   41 (22)  283   283 (0)      9     35 (21)   71   48     1*    5     34
    FDandMarketing  14   51 (11)   14    25 (5)     16     34 (8)    92   50    12    70    125
    ITDepartment    35   52 (10)   35    35 (0)     35     41 (4)    47   19     6    40     31
    SAProgram        0   43 (18)    0     0 (0)      0      4 (5)    24    7     9   129     69
    Services         0   42 (12)   54    54 (0)     16     41 (13)   66   29     1*    7    100
    KidsandYouth    35   64 (21)   35    35 (0)     35     35 (0)    20   15     1     3      8

    * rubber-stamp rows: replay-of-all worse than random mean, so the
      ddmin bar was trivial.  Trust keys only where lo(all)~=lo(b4).

## Highlights

1. SPEED: ~100x per evaluation (42us/world vs 4.5ms/eval on
   Services), ~1000x per pipeline row (0.1s vs 98s).  Whole corpus:
   0.4s vs ~3.5min.  Claimable: two to three orders of magnitude --
   the same margin SHORT claimed over ITS baseline.
2. shortr1 cannot say no: no demands, no dead worlds, hard goals
   merely counted.  shortr2's hard goals are hard.
3. shortr1 is optimistic twice over: first-positive-contributor
   scoring lets one helps hide every hurts; cycles hand goals t for
   free with no undo.
4. shortr1 never met the head-abduction problem: decisions are
   leaves-only by construction and eval is deterministic given
   leaves (mu(all) sd = 0 everywhere).  Price: it cannot state,
   test, or replay a claim about any internal goal.
5. Keys differ for a structural reason: shortr1's leaves coin-toss
   freely, so almost nothing is unanimous (shared 2-10) -> 3-20
   keys.  shortr2's constraint propagation forces 29-61 of the pool
   before ddmin starts -> 1-12 keys.
6. Same headline both engines, independent code: a few percent of
   decisions pin the outcome.  Keys are a phenomenon, not an
   implementation artifact.

## Histogram fodder

    model         ms(s1)   ms(s2)  ratio   keys(s1)  keys(s2)
    Counselling   46423    49      947x    7         1*
    CnslMgmt      9928     34      292x    7         1*
    FDandMkting   42393    125     339x    13        12
    ITDept        6030     31      195x    5         6
    SAProgram     2576     69      37x     3         9
    Services      98300    100     983x    20        1*
    KidsandYouth  1986     8       248x    16        1

Caveats: shortr1 timed under python3 after mechanical py2 fixes (no
algorithmic change); ddmin is path-dependent so keys wobble a few
labels across candidate orderings; starred rows above.
