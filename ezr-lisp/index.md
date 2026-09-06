<center>
<h2>Easier AI</h2>
<h3>explainable multi-objective active learning, in a few hundred lines</h3>
<p class="f">Menzies &middot; 2026<br>
<a href="https://github.com/timm">github.com/timm</a> &middot;
y1.py (structured) &middot; y2.py (naked structs)</p>
<p class="f">
<a href="index.html">0 start</a> &middot;
<a href="data.html">1 data</a> &middot;
<a href="dist.html">2 distance</a> &middot;
<a href="acquire.html">3 acquire</a> &middot;
<a href="tree.html">4 tree</a> &middot;
<a href="eval.html">5 eval</a> &middot;
<a href="maths.html">&#9733; maths</a></p>
</center>

<p class="card"><i>&ldquo;AI is easy (sometimes). Let me show
you how.&rdquo;</i>

But first, why study easier AI?
Modern AI, based on very complex large language models,
is astonishing. Given enough data, labels, and
electricity, large models draft our code, rank our options,
and answer in fluent paragraphs. But the bill for
&ldquo;enough&rdquo; keeps growing: more power than we can
generate, more water than we can spare, models too large to
audit and too expensive to retrain. And Bainbridge (1983)
warned of a subtler cost: if we automate all the easy stuff
then humans are left with the harder stuff,
but with skills
that have withered from disuse. To say that another way,
the better the model, the
fewer engineers who can catch it when it is wrong.

So here we go the other direction: seven tricks that make AI
simple, fast, and understandable &mdash; even for complex
problems:

- Go neuro-symbolic: smmybols sstesms smaller and simpler. combine with heuro

-  Satisfice (Simon, 1956) is the general umbrella — stop at good enough, don't pay for optimal. But it's about stopping criteria, not about indistinguishability, so it only half-fits.

Domain ananalys:
Parnas (1976) tells us to study the domain first, harvest its recurring parts, then build applications by assembling parts. If you do this right, then the more you code, the more new things
are just recombiantions of old things.  For example, once you can cluster data into related
groups, then regression is just  find your cloests cluster; then report the mean
value in that cluster. After that:
-  classification is the same thing, but report the most common symbol;
- anomaly detection means raising an alert of the nearest cluster is unuually far awat;
- optimization means find the delta betweena your nearest cluser and  another cluster with
  better predictions
- etc. 

- Active learning:
  Normal learners struggle to understand all data. _Active learners_ decide what
  to look at next by reflecting on over the data seen to data.
  By focusing only on the most informative data, active learners avoid all the
  superplous, reducndant, and noisy data. In this way, active learnerscan be built 
good models from tiny
  samples of data.
- Near enough optimization. Many real world phonenomum can only be controlled plus or minus
  some small epsilon. This means that reasoning can stop if we  get near enough to the 
  goal. Assuming Cohen's rule (two samples differ by a trivially small amount if their
difference is less that _.35&sigma;_. For solutions drawn from a normal curve 
_&pm;3_ standard devistions wide, _.35/6 &approx; 6%_   indistiguisahly if they deBetter yet, if some prior study has a model that can  hueristically  sort
  candidate options, then a 

This is surprisingly useful, 

: when people design lots of related things, then under the hood,
those things have many connections. This means that once you code
the first few things, everything else become combinations of what was already done. 

 coding a few
requureents, the remainint tasks can be built  just synonyms that combine  Lots of little tools: look for the parts inside the
  wholes. First requirements cost code; later ones are
  pipes through parts you already own. Bell Labs said
  tools, not products (Kernighan &amp; Plauger 1976); the
  1990s called it domain engineering; either way,
  classification here cost 15 lines, since entropy is
  just the div() of a symbolic column.

- Synonyms: In any domain then the first few requirements
need a lot of code. But if you've done your planning
right, the next requrement is just some
mash up of code already written. 


 These methods cannot yet do everything that (say)
ChatGPT can do. But note that the big models are the product
of trillion-dollar infrastructure and armies of engineers,
while everything on this site is the work of one professor
and a few graduate students over five years. Given a few
billion dollars, I could probably catch up. Until then, it
seems worth asking how far half a dozen people can get on
curiosity alone. The answer, it turns out: thirty labels, a
few hundred lines of code, near-best answers &mdash;
explained in a tree that fits on a card.

So here, we go the other direction and show seven tricks that make
AI simple, fast, understandtable even for complex problems.
These methods cannot do everything that (say) ChatGPT can do, yet. But
all this is the work of me and a few gradaute students over the last five
years.  Given a few billion dollars I should be able to catch up but for the mo

explores the other direction: what is the <i>least</i> a
model needs? Thirty labels and a few hundred lines of code
find near-best options in ten-thousand-row spaces &mdash;
and explain themselves in a tree that fits on a card.</p>

<p class="card"><i>&ldquo;AI is easy (sometimes). Let me show you how.&rdquo;</i>

<p class="card">But why care about easier AI?
At the time of this writing (2026), it is very clear that great things are possible
if we use very expensive AI methods. But it is also clear that those methods have
a cost: they need too much power; there is not enough water to cool those data centers;
AI empowers organizations but deskills works, especially newcomers who never learn the details
taht turn newibies into the kind of seior engineers we can rely on to design the next generation of
solutions, or to handle diffetulc problems asscaited with current technogies. 

 the less they it is very clear that much can be done 
Fifty labels, split 45/5 between hunting and checking, find rows
within a whisker of best &mdash; on 127 data sets, at a median win
of 87%. The whole learner: ~230 lines, no imports beyond the
standard library.</p>

<p class="card"><b class="q">How many labels does anyone really need?</b><br>
To be 95% sure of hitting a region holding fraction <i>p</i> of all
candidates, label <i>n &ge; log(1&minus;.95)/log(1&minus;p) &asymp; 3/p</i>.
A ranker that lifts the good region to <i>p&asymp;10%</i> of its top
picks needs ~30 checks &mdash; independent of population size.</p>

<pre class="py">
  d2h   n   Lbs-   Acc+   Mpg+
   36  50   2378     16     31
   25  27   2034     17     35   Volume &lt;= 98
   18  14   1985     18     36   |  origin = 3
+  12   5   1984     18     42   |  |  Model &gt; 79
   48  23   2782     16     27   Volume &gt; 98
-  65   6   3123     14     20   |  Model &lt;= 75
</pre>
<p class="cap">A 50-label tree of auto93 (398 rows): best (+) and
worst (&minus;) leaves flagged; goals summarized per node.</p>

<hr>

<p class="card"><b class="q">Does it scale?</b><br>
xomo_flight: 10,000 rows, 31 attributes, 4 goals. Thirty labels,
0.33 seconds, holdout win 94% &mdash; and the tree still fits on
a card.</p>

<pre class="py">
DATA, AAX,  ACAP, ... EFFORT-, MONTHS-, DEFECTS-, RISKS-
2.833, 3.81, 3.78, ...    1682,      36,     9129,   0.00
2.043, 3.73, 3.09, ...    2677,      40,    16727,   0.27
2.783, 3.26, 4.24, ...    1298,      31,     5623,   0.54
...   (9,997 more rows; only 30 ever labelled)
</pre>

<pre class="py">
  d2h  n EFFRT- MNTHS- DEFCT- RISK-
   39 30    735     25   4464     0
   31 21    473     23   2567     0  KLOC &lt;= 243
   34 17    516     23   2870     0  |  ACAP &lt;= 4.6
   27  6    346     21   1953     0  |  |  DATA &lt;= 2.8
   38 11    608     25   3370     0  |  |  DATA &gt; 2.8
   41  5    487     22   2128     1  |  |  |  RUSE &lt;= 3.8
   35  6    709     27   4406     0  |  |  |  RUSE &gt; 3.8
+  20  4    292     19   1276     0  |  ACAP &gt; 4.6
   56  9   1346     32   8890     1  KLOC &gt; 243
   41  4   1048     30   4715     0  |  STOR &lt;= 3.3
-  69  5   1584     34  12230     1  |  STOR &gt; 3.3
</pre>
<p class="cap">30 questions asked of a 10,000-row space: small
systems (KLOC&le;243) built by capable analysts (ACAP&gt;4.61)
need a fifth of the effort and a tenth of the defects of the
worst corner.</p>

<hr>
<p class="f"><center>&copy; 2026 Tim Menzies, MIT license</center></p>
