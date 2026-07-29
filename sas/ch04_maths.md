# A Little Maths

Six pieces of maths run the whole book: two summaries, a rescaling, a distance, a
random stream, and a trust test. None needs more than high-school algebra. Each gets
a demo here and a citation for readers who want the long form. But first, some words.

## Four kinds of column, two survive

Statistics sorts columns into four scales, by what you may do to their values:
nominal (names; test equality, nothing else), ordinal (ranks; also sort), interval
(also subtract), and ratio (also divide) [@stevens46]. The acronym is **NOIR**. This
book keeps the two ends. Names become `Sym` and numbers become `Num`; the middle two
get treated as one or the other.

%%code src/lib.py Sym

%%code src/lib.py Num

Every column summary answers the same two questions. Where is the middle? That is
central tendency: the mean mu for `Num`, the mode (the commonest symbol) for `Sym`.
How far do values stray from that middle? That is dispersion: the standard deviation
for `Num`, the entropy for `Sym`. The next two sections build those four answers, one
value at a time.

Two more words before we start. A **pdf** (probability density function) scores how
likely each value is; its familiar picture is the bell curve. A **cdf** (cumulative
distribution function) reports what fraction of the data sits at or below v. Whatever
the units, a cdf runs 0..1. Remember that; it is about to earn its keep.

## Center and spread, one value at a time

For numbers we track the mean and the standard deviation. The textbook formula for
variance wants two passes and a stored list. Welford's update [@welford62] wants
neither. Keep three slots (n, mu, m2). On each new value v, let d = v - mu. Then mu
moves by d/n, and m2 grows by d times the *new* gap (v - mu). The standard deviation
is (m2 / (n - 1)) raised to 0.5, on demand.

%%code src/lib.py welford

One pass. No stored raws. Constant memory. Symbols are easier. Count them:

%%code src/lib.py count

The public face of both updaters is one function, `add`, which reads a summary's
`it` tag, skips the "?" that marks a missing value, and hands the value to the
right updater. Its code waits for Chapter 5, where it also learns to fold rows into
tables. All the cleverness lives in the parts shown above.

## Entropy is just counting

For a bag of symbols with counts k out of n, the entropy
is the sum over symbols of -(k/n) log2 (k/n). It measures
surprise: how many yes-or-no questions, on average, to
name the next symbol. Take the bag "aaaabbc", so n = 7
and the counts are 4, 2, 1. The three terms are
-(4/7) log2 (4/7) = 0.461, -(2/7) log2 (2/7) = 0.516, and
-(1/7) log2 (1/7) = 0.401. Their sum is 0.461 + 0.516 +
0.401 = 1.379 bits.^[Purists will note we never round
away the working. House rule.] In code, the two middles
share one roof, and so do the two diversities. (We say
"diversity", div, not "variance", since variance names
sd squared and we report sd.)

%%code src/lib.py entropy

%%code src/lib.py mid

%%code src/lib.py div

The demo checks the entropy arithmetic above, then checks Welford against 10,000
samples from a unit gaussian:

%%run python3 src/lib_eg.py cols

## Nothing is comparable until it is 0..1

In auto93, weight runs in the thousands of pounds while acceleration runs in the tens
of seconds. Any distance computed on raw values would be a weight measure wearing a
distance costume. Hence, before comparing, we normalize using the normal: map each
number to its column's cdf, the fraction of the bell curve at or below v. We compute
that with the logistic curve 1 / (1 + e^(-1.702 z)), where z = (v - mu) / sd. Why
1.702? That constant pulls the logistic onto the gaussian cdf, to within 0.01
everywhere [@camilli94]. And unlike the error function, e^x exists in every language
this code will ever be ported to.^[An older habit rescales by the seen range, (v -
lo) / (hi - lo). That wants two more slots and its own epsilon, and one wild outlier
squashes everyone else into a corner. The cdf runs on what Welford already keeps.]
Whatever the units, the result runs 0..1.

%%code src/lib.py norm

A tiny epsilon guards the degenerate column whose sd is zero. Numerical hygiene of
that kind (a TINY here, a max(m2, 0) there) is not fussiness. It is where AI code
goes to die, quietly.

## One distance, three classics

With every gap scaled to 0..1, we aggregate gaps by the Minkowski formula: the p-th
root of the mean of the p-th powers [@menzies26ezr]. One knob, three famous
distances: p = 1 is city-block, p = 2 is Euclidean, and large p approaches Chebyshev
(the max gap wins). For two gaps of 0.3 and 0.4 at p = 2, that is ((0.09 + 0.16) / 2)
^ 0.5 = (0.125) ^ 0.5 = 0.354. You will meet the code in Chapter 5, written out
longhand inside the two distance functions. Distance sits in every inner loop this
book runs, so those functions stay flat: one call to norm per gap, and nothing else.

## Random streams are lab equipment

Every stochastic demo in this book starts by seeding the random stream, so every
transcript reproduces. Treat the generator as lab equipment: calibrated, logged,
reset between experiments. When we later port code across languages, we will go
further and use Lehmer's portable generator with multiplier 16807, which is 7 * 7 * 7
* 7 * 7 = 16807, i.e. 7^5 [@park88]. Same seed, same stream, in every language. Five
printed draws then certify a port before any learner runs.

## The trust test

Later chapters keep saying "X beats Y". Such talk is cheap, so we tax it. We ask
the question backward, "are these the same?", since sameness is the common case
and the common case should be cheap. Three tests judge, and one sort powers all
three: same() sorts both lists once, then asks each judge in turn, cheapest first.
Cohen's rule reads three indexes per list (middles within 0.35 spreads, where the
spread is the 10th-to-90th percentile stretch over 2.56, since that stretch is
2.56 sds on a gaussian) [@cohen88]. Kolmogorov-Smirnov merges (cdf gap under the
5% critical value 1.36 sqrt((n + m) / nm)) [@massey51]. Cliff's delta
binary-searches (rank shift within the 0.197 threshold) [@cliff93; @hess04]. The
last two are the standard prescription for empirical work (one significance test,
one effect-size test); the first is a cheap tie-breaker that keeps variance-only
wobbles from passing as victories. Note the or-chain inside same(): the first
judge to say "same" ends the trial, so the dear tests run only on the close
calls, and only a pair that gets past all three may be called different. Watch it
work on a gaussian nudged by ever-larger shifts. Shifts of 0.1, 0.3, even 0.5
standard deviations pass as same (at 0.5, Cohen sees a difference but
Kolmogorov-Smirnov holds out). Only from a full standard deviation do all three
agree, and only then is the pair called different:

%%run python3 src/lib_eg.py stats

Note the humility this buys. Any single test can be gamed, and p-values alone say
nothing about effect size. Demanding that a pair get past an effect-size test and
a distribution test before crying "difference" makes our later victory claims
conservative. When this book says "beats", it has cleared all three bars.

## Lessons sighted

**NOIR** and the two surviving scales; Welford's one-pass
update;
entropy as counted surprise; cdf normalization and
epsilon hygiene; the Minkowski family; seeds as lab
equipment
(with **PRNG** portability via 7^5); and the lazy
three-judge trust test. That last one is this book's
referee. It sits in the substrate, before any learner, on
purpose.
