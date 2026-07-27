import json,sys,re
# Contributions keep weights; structure keeps its kind:
# dep/2 = dependency (conjunctive, per the reference propagate()),
# dec/3 = or/and decomposition. An earlier j2pl flattened all of
# these to weight-1 edges; that erased dependency and-semantics.
W = dict(make=1, help=0.5, someplus=0.5, hurt=-0.5,
         someminus=-0.5, breaks=-1); W["break"]=-1
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
print("% "+d["name"]+"  (node/2 edge/3 dep/2 dec/3 leaf/1 topgoal/1)")
print(":- discontiguous node/2, edge/3, dep/2, dec/3, leaf/1, topgoal/1.")
print(":- dynamic node/2, edge/3, dep/2, dec/3, leaf/1, topgoal/1.")
incoming = {n["id"]:0 for n in d["nodes"]}
for e in d["edges"]:
    if e["source"] in atom and e["target"] in atom: incoming[e["target"]] += 1
for n in d["nodes"]:
    print("node(%s,%s)." % (atom[n["id"]], n["type"]))
    if incoming[n["id"]]==0: print("leaf(%s)."    % atom[n["id"]])
    if n["type"]=="goal":    print("topgoal(%s)." % atom[n["id"]])
for e in d["edges"]:
    if e["source"] in atom and e["target"] in atom:
        c, p, v = atom[e["source"]], atom[e["target"]], e["value"]
        if   v == "dependency": print("dep(%s,%s)." % (c,p))
        elif v in ("or","and"): print("dec(%s,%s,%s)." % (c,p,v))
        else:                   print("edge(%s,%s,%s)." % (c,p,W[v]))
