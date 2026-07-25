# AI: Less, but Better

Tim Menzies   
timm@ieee.org

"Inside every large program is a   
small program struggling to get out."  
--  C.A.R. Hoare

## Introduction

What if there were another way to AI?
Someway where the
working parts fit in a few hundred lines; that trains in seconds, on a
laptop; whose conclusions are short enough to read in one sitting and
change before lunch?

Let's try and build that other way. For example,

## The Basic

AI lets us build models, some of which we can read and understand,
some of which are useful.

Models are build from experience and experience is stored in data.
For example, suppose we are looking to buy a car.
Good cars are lighter (so cheaper to buld), accelate faster,
and use less fuel. Someone offers us the following car:

    Clndrs, Volume, HpX, Model, origin, Lbs-, Acc+, Mpg+
         4,    140,  92,    76,      1, 2572, 14.9,   30

Is this an unusual car? Would some other car be better?  If we had to
buy this car, what are the least change could most improve it?

We can answer these qestion suign some basic AI operators: "cluster"
and "predict".
Clustering means grouping related things toether
and prediction find reorted the expected value of the relevant group.

    Clndrs, Volume, HpX, Model, origin, Lbs-, Acc+, Mpg+, | disty

         4,     90,  48,    78,      2, 1985, 21.5,   40, |  0.07
         4,     98,  68,    78,      1, 2155, 16.5,   30, |  0.26
        ...
         4,    140,  92,    76,      1, 2572, 14.9,   30, |  0.41
         4,     97,  54,    72,      2, 2254, 23.5,   20, |  0.41
        ...
         6,    131, 103,    78,      2, 2830, 15.9,   20, |  0.54
         6,    232, 100,    71,      1, 3288, 15.5,   20, |  0.62
         8,    305, 145,    77,      1, 3880, 12.5,   20, |  0.81
         8,    454, 220,    70,      1, 4354,    9,   10, |  0.96

The first thing we need to do is 

### Lessons:

- Don't think, remember. 
- 

# References
