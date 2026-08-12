# rp.py vs ezr-lua: label-budget experiments (2026-08-07)

All scores = ezr's disty yardstick (full-file mu/sd, logistic norm,
minkowski p=2; 0=best) unless noted. 20 seeds per cell. "same()" =
ezr's cohen<=.35 & cliffs<=.195 & ks<=1.36 on 20v20 samples.
rp config unless noted: B=7 bins, N=3, eras=9, eps=.05, f=15, check=5.

## Lesson 0: normalization scandal

rp's printed d normalizes over its ~27 train rows only. Scored that
way rp "won 8/10" with four fake 0.000s. Same rows rescored on the
full-file yardstick: rp wins 0. Never compare optimizers across
different normalizations.

## 10 random moot datasets, rp (~21-32 labels) vs ezr budget=50

median disty, winner via same():

    data                     rpcost     rp  ezr50  winner
    dataset600                   21  0.031  0.030  ezr
    SS-T                         31  0.307  0.280  ezr
    Health-Commits0004           32  0.293  0.300  tie
    wc-6d-c1-obj1                32  0.092  0.090  tie
    FFM-1000-200-0.50-SAT-1       6  0.445  0.360  ezr
    rs-6d-c3_obj2                32  0.348  0.350  rp
    storm                        32  0.231  0.230  ezr
    X264_AllMeasurements         32  0.098  0.090  ezr
    SS-R                         31  0.289  0.285  tie
    Wine_quality                 32  0.327  0.255  ezr
    rp 1, ezr 6, tie 3

Medians often identical to 3rd decimal; ezr wins on per-seed
variance (tighter distributions), not central tendency.

## All-moot sweep (118 datasets, mean disty, delta=rp-ezr50, 0 if same())

    rp better 12, ties 21, ezr better 85
    best rp win  Health-ClosedIssues0003  -0.077
    worst loss   Data_COVID19_Indonesia   +0.374

Half of ezr's wins are delta <= +.05. Catastrophic rp losses all
share tiny cost (6-13 labels): FM/FFM family, Loan, COVID19,
Life_Expectancy, Scrum1k. Failure mode = delegate collapse:
city-block distance over many/wide columns concentrates, everything
lands within eps of the first row, cover stops at 1 delegate.
Skipped: 8 files >50k rows, student_dropout (bool goal).

## Can hyperparameters fix it? No.

1000 random configs (B 4-16, N 2-10, eras 4-30, eps .01-.15 log,
f in {0,5,10,15,20}), hard cap cost<=50, objective = mean delta vs
ezr50 over the 10 datasets, staged 1000x(4ds,3seed) -> 100x(10ds,
5seed) -> top5 verified 20 seeds:

    #1 (B=4,N=3,eras=18,eps=.139,f=10)  rp 2, tie 2, ezr 6
    ... all five: rp 1-2, tie 1-3, ezr 5-7

Best tuned delta +.009 mean — close on average, still loses same()
on most datasets, and every top config still collapses to cost=6 on
FFM (200 x-cols). Tuned ON these datasets, so real-world is worse.

## Standing conclusions

- rp at ~30 labels ties ezr at 50 on ~1/4 to 1/2 of datasets;
  never meaningfully beats it. Its pitch: fixed small cost +
  explainable grid, not optimization strength.
- Gap is structural, not parametric: (1) global fixed eps vs
  per-dataset distance scale -> collapse on wide data; (2)
  unsupervised coverage vs ezr's adaptive acquire.
- Candidate fixes (unimplemented, per "leave rp as is"): eps from
  sampled pairwise train-distance percentile; feature subsampling
  for wide data.
- earlier auto93-only tuning: winning region N=3, B=6-7,
  eps .04-.07, f=10-15; f (retreat percentile in far()) genuinely
  helps - f=0 sat in the worst quartile.
