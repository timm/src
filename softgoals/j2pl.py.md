# j2pl.py

{% raw %}
```text

```

```python
import json,sys,re,collections
# Emit the nfr3 dialect: one arrow. Structure is Horn rules (list
# body = and, multiple clauses = or; dependencies are conjuncts
# repeated in every alternative); contributions are one more <--
# clause per head, its body the soft terms (makes/helps/hurts/
# breaks). Types are never declared: nfr3 derives rule/edge/leaf
# from clause shapes. The two facts that are not derivable ship as
# goal clauses instead: goals(hard) <-- [each type-goal node] and
# goals(soft) <-- [or([each type-softgoal node])]. Nodes of other
# types that appear in no clause are dropped (they cannot affect
# any inference).
C = dict(make="makes", help="helps", someplus="helps",
         hurt="hurts", someminus="hurts", breaks="breaks")
C["break"] = "breaks"
d = json.load(open(sys.argv[1]))
def camel(s):
    ws = re.findall(r"[A-Za-z0-9]+", re.sub(r"[^\x20-\x7e]"," ",s.replace("\\ns"," ")))
    a  = (ws or ["x"])[0].lower() + "".join(w[0].upper()+w[1:] for w in ws[1:])
    return a if a[0].isalpha() else "x"+a
atom, seen = {}, {}
for n in d["nodes"]:                       # unique unquoted atoms per node
    a = camel(str(n.get("name") or n["id"])); k, a0 = 2, a
    while a in seen: a = "%s%d" % (a0,k); k += 1
    seen[a] = 1; atom[n["id"]] = a
print("% "+d["name"]+"  (nfr3 dialect: <-- rules, soft bodies are edges)")
print(":- discontiguous (<--)/2.")
print(":- dynamic (<--)/2.")
deps = collections.defaultdict(list)       # parent -> mandatory kids
ors  = collections.defaultdict(list)       # parent -> alternative kids
ands = collections.defaultdict(list)       # parent -> and-decomp kids
con  = collections.defaultdict(list)       # parent -> contribution terms
for e in d["edges"]:
    if e["source"] in atom and e["target"] in atom:
        c, p, v = atom[e["source"]], atom[e["target"]], e["value"]
        if   v == "dependency": deps[p].append(c)
        elif v == "or":         ors[p].append(c)
        elif v == "and":        ands[p].append(c)
        else:                   con[p].append("%s(%s)" % (C[v],c))
def pp(head, items, ind="    "):
    one = "%s <-- [%s]." % (head, ", ".join(items))
    if len(one) <= 70: print(one); return
    print("%s <--" % head)
    for i, it in enumerate(items):
        pre = "  [ " if i == 0 else ind
        end = " ]." if i == len(items)-1 else ","
        print("%s%s%s" % (pre, it, end))
bytype = collections.defaultdict(list)
for n in d["nodes"]: bytype[n["type"]].append(atom[n["id"]])
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