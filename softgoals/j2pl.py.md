# j2pl.py

{% raw %}
```text

```

```python
import json,sys,re
W = dict(make=1, dependency=1, help=0.5, someplus=0.5, hurt=-0.5,
         someminus=-0.5, breaks=-1); W["break"]=-1; W["or"]=1; W["and"]=1
d = json.load(open(sys.argv[1]))
def camel(s):
    ws = re.findall(r"[A-Za-z0-9]+", re.sub(r"[^\x20-\x7e]"," ",s.replace("\\ns"," ")))
    a  = (ws or ["x"])[0].lower() + "".join(w[0].upper()+w[1:] for w in ws[1:])
    return a if a[0].isalpha() else "x"+a
atom, seen = {}, {}
for n in d["nodes"]:                       # unique unquoted atoms per node
    a = camel(n["id"]); k, a0 = 2, a
    while a in seen: a = "%s%d" % (a0,k); k += 1
    seen[a] = 1; atom[n["id"]] = a
print("% "+d["name"]+"  (edit me: node/2 edge/3 leaf/1 topgoal/1)")
print(":- discontiguous node/2, edge/3, leaf/1, topgoal/1.")
print(":- dynamic node/2, edge/3, leaf/1, topgoal/1.")
incoming = {n["id"]:0 for n in d["nodes"]}
for e in d["edges"]:
    if e["source"] in atom and e["target"] in atom: incoming[e["target"]] += 1
for n in d["nodes"]:
    print("node(%s,%s)." % (atom[n["id"]], n["type"]))
    if incoming[n["id"]]==0: print("leaf(%s)."    % atom[n["id"]])
    if n["type"]=="goal":    print("topgoal(%s)." % atom[n["id"]])
for e in d["edges"]:
    if e["source"] in atom and e["target"] in atom:
        print("edge(%s,%s,%s)." % (atom[e["source"]], atom[e["target"]], W[e["value"]]))
```

{% endraw %}