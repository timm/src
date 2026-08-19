# less.lua

{% raw %}
```text
# AI is Easy?

Lets play a game called AI golf. Starting with a set of tasks,
what's the least code we need to implement those tasks?

One way to write less new code is to reuse  old code.  Suppose your
AIs have skills to help you buy a car. If we  code those skills
then at some point, new skills are just recombinations of the older
skills. For example, here we code up the following skills. After some
initial set up (that needed 45% of the code), the remaining system needed
less and less.


| task                          | skill                     | %LOC | new LOC |
|-------------------------------|---------------------------|-----:|--------:|
| Study 400 cars; measure gaps  | remember (representation) | 45%  | 150 |
| Guess fuel use, unseen        | guess (prediction)        | 17%  |  57 |
| Real "better", or noise?      | certify (certification)   | 12%  |  40 |
| Decide as cars arrive         | flow (streaming)          |  8%  |  27 |
| Why are bad cars bad?         | blame (diagnosis)         |  6%  |  20 |
| Convince a skeptic            | justify (explanation)     |  4%  |  13 |
| Best car, few test drives     | choose (optimization)     |  3%  |  10 |
| Cheapest fix for this car     | fix (repair)              |  3%  |  10 |
| Spot typo, or scam            | spot (anomaly detection)  |  2%  |   6 |
| Race the field's best         | race (baselining)         |  0%  |   0 |
| **Totals**                    |                           | **100%** | **333** |

Having played this AI golf games, As we show below,  the total amount of code needed for all these tasks is very
short (just a few hundred lines).

So is their an alterntive?  Not for the generative tasks, but what
else can we do to a
What I find is that, in any domain, if you do task1, task2,,task3, etc
then once you  the time you complete some tasks, theer is  

Lets start simle and see how far we can go. At the lowest level there
and numbers and symbol.

Before anything else,  we need some Lua magic to catch new variables
and to dispatch messages.  Its a little arcane
AI is complex, slow, and hard to understand, right?

Maybe not. For years I've been playing a game called "AI golf" where I refactor
old AI code into something shorter. It turns out that  
--
```

```lua
# AI is Easy?

Lets play a game called AI golf. Starting with a set of tasks,
what's the least code we need to implement those tasks?

One way to write less new code is to reuse  old code.  Suppose your
AIs have skills to help you buy a car. If we  code those skills
then at some point, new skills are just recombinations of the older
skills. For example, here we code up the following skills. After some
initial set up (that needed 45% of the code), the remaining system needed
less and less.


| task                          | skill                     | %LOC | new LOC |
|-------------------------------|---------------------------|-----:|--------:|
| Study 400 cars; measure gaps  | remember (representation) | 45%  | 150 |
| Guess fuel use, unseen        | guess (prediction)        | 17%  |  57 |
| Real "better", or noise?      | certify (certification)   | 12%  |  40 |
| Decide as cars arrive         | flow (streaming)          |  8%  |  27 |
| Why are bad cars bad?         | blame (diagnosis)         |  6%  |  20 |
| Convince a skeptic            | justify (explanation)     |  4%  |  13 |
| Best car, few test drives     | choose (optimization)     |  3%  |  10 |
| Cheapest fix for this car     | fix (repair)              |  3%  |  10 |
| Spot typo, or scam            | spot (anomaly detection)  |  2%  |   6 |
| Race the field's best         | race (baselining)         |  0%  |   0 |
| **Totals**                    |                           | **100%** | **333** |

Having played this AI golf games, As we show below,  the total amount of code needed for all these tasks is very
short (just a few hundred lines).

So is their an alterntive?  Not for the generative tasks, but what
else can we do to a
What I find is that, in any domain, if you do task1, task2,,task3, etc
then once you  the time you complete some tasks, theer is  

Lets start simle and see how far we can go. At the lowest level there
and numbers and symbol.

Before anything else,  we need some Lua magic to catch new variables
and to dispatch messages.  Its a little arcane
AI is complex, slow, and hard to understand, right?

Maybe not. For years I've been playing a game called "AI golf" where I refactor
old AI code into something shorter. It turns out that  
--]]
local _ENV = setmetatable({}, {__index = require"ezr-lib"})
if setfenv then setfenv(1, _ENV) end

function new(klass,t) -- set up method dispatch in LUA
  klass.__index=klass; return setmetatable(t,klass) end

function Col(s,at)
  s = s or ""
  i = (s:find"^[A-Z]" and Num or Sym)()
  i.at=at or 1; i.txt=s; i.goal=s:find"-$" and 0 or 1
  return i end
```

{% endraw %}