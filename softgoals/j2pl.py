import json,sys,re,collections
# Emit the nfr2 dialect: structure as Horn rules (list body = and,
# multiple clauses = or; dependencies are conjuncts repeated in
# every alternative), contributions as one G <~ [..] edge list.
# node/2, leaf/1, topgoal/1 kept as facts for the runner.
C = dict(make="make", help="help", someplus="help",
         hurt="hurt", someminus="hurt", breaks="break")
C["break"] = "break"
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
print("% "+d["name"]+"  (nfr2 dialect: <- rules, <~ contribution lists)")
print(":- discontiguous (<-)/2, (<~)/2, node/2, leaf/1, topgoal/1.")
print(":- dynamic (<-)/2, (<~)/2, node/2, leaf/1, topgoal/1.")
deps = collections.defaultdict(list)       # parent -> mandatory kids
ors  = collections.defaultdict(list)       # parent -> alternative kids
ands = collections.defaultdict(list)       # parent -> and-decomp kids
con  = collections.defaultdict(list)       # parent -> contribution terms
incoming = {n["id"]:0 for n in d["nodes"]}
for e in d["edges"]:
    if e["source"] in atom and e["target"] in atom:
        incoming[e["target"]] += 1
        c, p, v = atom[e["source"]], atom[e["target"]], e["value"]
        if   v == "dependency": deps[p].append(c)
        elif v == "or":         ors[p].append(c)
        elif v == "and":        ands[p].append(c)
        else:                   con[p].append("%s(%s)" % (C[v],c))
for n in d["nodes"]:
    print("node(%s,%s)." % (atom[n["id"]], n["type"]))
    if incoming[n["id"]]==0: print("leaf(%s)."    % atom[n["id"]])
    if n["type"]=="goal":    print("topgoal(%s)." % atom[n["id"]])
def pp(head, op, items):
    one = "%s %s [%s]." % (head, op, ", ".join(items))
    if len(one) <= 70: print(one); return
    print("%s %s" % (head, op))
    for i, it in enumerate(items):
        pre = "  [ " if i == 0 else "    "
        end = " ]." if i == len(items)-1 else ","
        print("%s%s%s" % (pre, it, end))
for p in sorted(set(list(deps)+list(ors)+list(ands))):
    must = deps[p] + ands[p]
    if ors[p]:
        for k in ors[p]: pp(p, "<-", must+[k])
    else:
        pp(p, "<-", must)
for p in sorted(con):
    pp(p, "<~", con[p])
