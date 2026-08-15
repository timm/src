% small  (nfr5 tagged dialect: [or|Gs] choice, bare list = and;
% hard goals gate via the query, no must)
:- discontiguous (<--)/2.
:- dynamic (<--)/2.
goals(hard) <-- [built, deployed].
goals(soft) <-- [or, cheap, fast, private].

built     <-- [or, buy, diy].
buy       <-- [vendor, breaks(cheap), helps(fast)].
diy       <-- [coders, helps(cheap), hurts(fast)].
deployed  <-- [or, cloud, onprem].
cloud     <-- [helps(fast), hurts(private)].
onprem    <-- [makes(private), hurts(fast)].
usable    <-- [tested, helps(fast)].
