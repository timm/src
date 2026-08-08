# i2pl.py

{% raw %}
```text

```

```python
import sys,re,collections
import xml.etree.ElementTree as ET
# istarml 1.0 XML -> nfr3 dialect, same output shape as j2pl/p2pl.
# Nesting gives link direction: <ielement A><ielementLink t>
# <ielement B/>... means B (and siblings) link INTO A. decomposition/
# task-decomposition/composition = and; means-end = or; contribution
# values map onto makes/helps/hurts/breaks (Some+/And lean positive,
# Some-/unknown-negative lean negative). A dependum's <dependency>
# unfolds as depender-element gets the dependum conjunct and
# dependum <-- [dependee-element]; sides given only as an actor are
# dropped.
CV = {"make":"makes","help":"helps","some+":"helps","and":"makes",
      "hurt":"hurts","some-":"hurts","break":"breaks","or":"helps",
      "unknown":"helps"}
AND = {"decomposition","task-decomposition","composition"}
OR  = {"means-end","mean-end"}
tree = ET.parse(sys.argv[1])
def camel(s):
    ws = re.findall(r"[A-Za-z0-9]+", re.sub(r"[^\x20-\x7e]"," ",s))
    a  = (ws or ["x"])[0].lower() + "".join(w[0].upper()+w[1:] for w in ws[1:])
    return a if a[0].isalpha() else "x"+a
byid, atom, seen, types = {}, {}, {}, {}
def intern(el):
    if el.get("iref"): return None             # reference, resolve later
    name = el.get("name") or el.get("id") or "x"
    a = camel(name); k, a0 = 2, a
    while a in seen: a = "%s%d" % (a0,k); k += 1
    seen[a] = 1
    if el.get("id"): byid[el.get("id")] = a
    atom[id(el)] = a
    types.setdefault(el.get("type","task"), []).append(a)
    return a
for el in tree.iter("ielement"): intern(el)
def resolve(el):
    return byid.get(el.get("iref")) if el.get("iref") else atom.get(id(el))
deps = collections.defaultdict(list)
ors  = collections.defaultdict(list)
ands = collections.defaultdict(list)
con  = collections.defaultdict(list)
for el in tree.iter("ielement"):
    p = resolve(el)
    if not p: continue
    for ln in el.findall("ielementLink"):
        t = (ln.get("type") or "").lower()
        kids = [resolve(k) for k in ln.findall("ielement")]
        kids = [k for k in kids if k]
        if not kids: continue                  # unresolved refs: no empty
        if t in AND: ands[p] += kids           # (trivially-true) rules
        elif t in OR: ors[p] += kids
        elif t == "contribution":
            v = CV.get((ln.get("value") or "help").lower(), "helps")
            con[p] += ["%s(%s)" % (v,k) for k in kids]
    for dp in el.findall("dependency"):
        der, dee = dp.find("depender"), dp.find("dependee")
        if der is not None and der.get("iref") and byid.get(der.get("iref")):
            deps[byid[der.get("iref")]].append(p)
        if dee is not None and dee.get("iref") and byid.get(dee.get("iref")):
            ors[p].append(byid[dee.get("iref")])
print("% "+re.sub(r"\.istarml$","",sys.argv[1].split("/")[-1])
      +"  (nfr3 dialect, from istarml)")
print(":- discontiguous (<--)/2.")
print(":- dynamic (<--)/2.")
def pp(head, items, ind="    "):
    if not items: return
    one = "%s <-- [%s]." % (head, ", ".join(items))
    if len(one) <= 70: print(one); return
    print("%s <--" % head)
    for i, it in enumerate(items):
        pre = "  [ " if i == 0 else ind
        end = " ]." if i == len(items)-1 else ","
        print("%s%s%s" % (pre, it, end))
if types.get("goal"): pp("goals(hard)", types["goal"])
if types.get("softgoal"):
    ss = types["softgoal"]
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