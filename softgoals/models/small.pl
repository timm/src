
start     <-- [and([must(built), must(deployed)]),   % hard side: all gate
               and([cheap, fast, private])].         % soft side: label all
built     <-- [or([buy, diy])].
buy       <-- [vendor, breaks(cheap), helps(fast)].
diy       <-- [coders, helps(cheap), hurts(fast)].
deployed  <-- [or([cloud, onprem])].
cloud     <-- [helps(fast), hurts(private)].
onprem    <-- [makes(private), hurts(fast)].
usable    <-- [tested, helps(fast)].
