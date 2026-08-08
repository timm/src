# p2pl.py

{% raw %}
```text

```

```python
import json,sys,re,collections
# piStar (iStar 2.0 tool) JSON -> nfr3 dialect. Same output shape as
# j2pl.py: Horn rules (multiple clauses = or-refinement, list body =
# and-refinement; NeededBy resources and dependency dependums are
# conjuncts), contributions as one more <-- clause whose body holds
# the soft terms, plus goals(hard) <-- [type-goal nodes] and
# goals(soft) <-- [or([type-quality nodes])]. Dependencies unfold as
# dependerElmt gets the dependum conjunct, dependum <-- [dependeeElmt];
# a side that names an actor instead of an element is dropped.
# Qualification/IsA/ParticipatesIn links carry no propagation
# semantics and are skipped.
C = dict(make="makes", help="helps", hurt="hurts")
C["break"] = "breaks"
d = json.load(open(sys.argv[1]))
def camel(s):
    ws = re.findall(r"[A-Za-z0-9]+", re.sub(r"[^\x20-\x7e]"," ",s))
    a  = (ws or ["x"])[0].lower() + "".join(w[0].upper()+w[1:] for w in ws[1:])
    return a if a[0].isalpha() else "x"+a
T = {"istar.Goal":"goal", "istar.Quality":"softgoal",
     "istar.Softgoal":"softgoal", "istar.Task":"task", "istar.Resource":"task"}
nodes = [n for a in d.get("actors",[]) for n in a.get("nodes",[])]
nodes += d.get("orphans",[]) + d.get("dependencies",[])
atom, seen = {}, {}
for n in nodes:
    a = camel(n["text"]); k, a0 = 2, a
    while a in seen: a = "%s%d" % (a0,k); k += 1
    seen[a] = 1; atom[n["id"]] = a
print("% "+re.sub(r"\.(json|txt)$","",sys.argv[1].split("/")[-1])
      +"  (nfr3 dialect, from piStar json)")
print(":- discontiguous (<--)/2.")
print(":- dynamic (<--)/2.")
deps = collections.defaultdict(list)
ors  = collections.defaultdict(list)
ands = collections.defaultdict(list)
con  = collections.defaultdict(list)
for l in d.get("links",[]):
    s, t = atom.get(l["source"]), atom.get(l["target"])
    if not (s and t): continue                 # actor-level link
    ty = l["type"]
    if   ty == "istar.AndRefinementLink": ands[t].append(s)
    elif ty == "istar.OrRefinementLink":  ors[t].append(s)
    elif ty == "istar.NeededByLink":      deps[t].append(s)
    elif ty == "istar.ContributionLink":
        con[t].append("%s(%s)" % (C.get(l.get("label","help").lower(),"helps"),s))
for dep in d.get("dependencies",[]):
    m = atom[dep["id"]]
    s, t = atom.get(dep.get("source")), atom.get(dep.get("target"))
    if s: deps[s].append(m)                    # depender needs the dependum
    if t: ors[m].append(t)                     # dependee's element provides it
def pp(head, items, ind="    "):
    if not items: return
    one = "%s <-- [%s]." % (head, ", ".join(items))
    if len(one) <= 70: print(one); return
    print("%s <--" % head)
    for i, it in enumerate(items):
        pre = "  [ " if i == 0 else ind
        end = " ]." if i == len(items)-1 else ","
        print("%s%s%s" % (pre, it, end))
bytype = collections.defaultdict(list)
for n in nodes:
    if n["id"] in atom and n.get("type") in T:
        bytype[T[n["type"]]].append(atom[n["id"]])
if bytype["goal"]: pp("goals(hard)", bytype["goal"])
if bytype["softgoal"]:
    ss = bytype["softgoal"]
    print("goals(soft) <--")
    for i, s in enumerate(ss):
        pre = "  [ or([ " if i == 0 else "         "
        end = " ]) ]." if i == len(ss)-1 else ","
        print("%s%s%s" % (pre, s, end))
for p in sorted(set(list(deps)+list(ors)+list(ands))):
    must = deps[p] + ands[p]
    if ors[p]:
        for k in ors[p]: pp(p, must+[k])
    else:
        pp(p, must)
for p in sorted(con):
    pp(p, con[p])
```

{% endraw %}