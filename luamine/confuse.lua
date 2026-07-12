-- Confuse. A confusion matrix: count (want,got) pairs, then
-- per-klass tn/fn/fp/tp and the derived acc/pred/pf/pd.
local l, the = ...

local Confuse = {}

-- ctor: confusion matrix counts + klass set
function Confuse.new(file)
  return l.new(Confuse, {t={}, klasses={}, file=file or ""}) end

-- bump count for (want,got) pair
function Confuse.add(i,want,got)
  i.t[want]       = i.t[want] or {}
  i.t[want][got]  = (i.t[want][got] or 0) + 1
  i.klasses[want], i.klasses[got] = true, true end

-- per-klass {tn,fn,fp,tp,acc,pred,pf,pd,...}
function Confuse.scores(i,    out,tn,fn,fp,tp,n)
  out = {}
  for _,klass in ipairs(
      l.sort(l.kap(i.klasses,
                   function(k,_) return k end))) do
    tn,fn,fp,tp = 0,0,0,0
    for want,gots in pairs(i.t) do
      for got,cnt in pairs(gots) do
        if     want==klass and got==klass then tp=tp+cnt
        elseif want==klass                then fn=fn+cnt
        elseif got==klass                 then fp=fp+cnt
        else   tn=tn+cnt end end end
    n = tn+fn+fp+tp
    out[1+#out] = {klass=klass, tn=tn, fn=fn, fp=fp, tp=tp,
      n=n, file=i.file,
      acc =100*(tp+tn)/(n+1e-32),
      pred=100*tp/(tp+fp+1e-32),
      pf  =100*fp/(fp+tn+1e-32),
      pd  =100*tp/(tp+fn+1e-32)} end
  return out end

-- print confusion stats as formatted table
function Confuse.show(i,    hdr,row)
  hdr = "%5s %5s %5s %5s %5s %5s %5s %5s %5s %-8s %s"
  row = "%5d %5d %5d %5d %5.0f %5.0f %5.0f %5.0f %5d %-8s %s"
  print(hdr:format("tn","fn","fp","tp","acc","pred","pf","pd",
                   "n","file","filename"))
  for _,r in ipairs(i:scores()) do
    print(row:format(r.tn, r.fn, r.fp, r.tp,
      r.acc, r.pred, r.pf, r.pd, r.n, r.klass, r.file)) end end

l.Confuse = Confuse
