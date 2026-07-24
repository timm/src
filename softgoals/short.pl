% engine2 : constraint-driven propagation; stagger kept where choice matters
:- dynamic label/2, sat/2.

prove(true)  :- !.
prove((A,B)) :- !, prove(A), prove(B).
prove(\+ G)  :- !, \+ prove(G).
prove(G)     :- predicate_property(G,built_in), !, call(G).
prove(G)     :- setof(R-(G-B),(clause(G,B),random(R)),Ps), member(_-(G-B),Ps),
                prove(B).

sat(N,_)     :- label(N,1).
sat(N,_)     :- leaf(N), \+ label(N,-1), lbl(N,1).
sat(N,Seen)  :- edge(K,N,W), W >= 0.5, \+ memberchk(K,Seen), sat(K,[N|Seen]).

expect(Vi,W,Vk) :- (Vi=:=1;Vi=:= -1) -> Vk is W*Vi ; W>0 -> Vk=Vi ; Vk is -Vi.

lbl(N,_)     :- label(N,_), !.                    % conflict? edge just ignored
lbl(N,V)     :- assert(label(N,V)),
                findall(K-W, edge(N,K,W), Es0),   % indexed: O(out-degree)
                random_permutation(Es0,Es),       % Fig 5: kids in random order
                forall(member(K-W,Es), (expect(V,W,Vk), lbl(K,Vk))).

pick(Gen,X)  :- setof(R-X0,(call(Gen,X0),random(R)),[_-X|_]).
unlab(L)     :- leaf(L), \+ label(L,_).
smpl         :- pick(unlab,L), !, (maybe->V=1;V= -1), lbl(L,V), smpl.
smpl.

wrld(As,SG,C):- retractall(label(_,_)),
                forall(topgoal(G),(prove(sat(G,[]))->true;true)), smpl,
                findall(L,(leaf(L),label(L,1)),As), length(As,C),
                aggregate_all(count,(node(S,softgoal),label(S,V),V>0),SG).

median(L,M)  :- msort(L,S), length(S,N), I is max(1,N//2), nth1(I,S,M).
iqr(L,Q)     :- msort(L,S), length(S,N), A is max(1,N//4), B is max(1,3*N//4),
                nth1(A,S,X), nth1(B,S,Y), Q is Y-X.
one(P,U)     :- retractall(label(_,_)), forall(member(D,P),lbl(D,1)), smpl,
                aggregate_all(count,(node(S,softgoal),label(S,V),V>0),SG),
                aggregate_all(count,(leaf(L),label(L,1)),C), U is SG-C.
eval(K,Ds,M,Q):- length(P,K), append(P,_,Ds),
                findall(U,(between(1,20,_),one(P,U)),Us), median(Us,M), iqr(Us,Q).
ranked(Ds)   :- findall(K-As,(between(1,100,_),wrld(As,SG,C),K is SG*100-C),Ws),
                sort(0,@>=,Ws,S), length(B,10), append(B,R,S), length(R,Nr),
                findall(V-D,(leaf(D),
                  aggregate_all(count,(member(_-A,B),memberchk(D,A)),BC),
                  aggregate_all(count,(member(_-A,R),memberchk(D,A)),RC),
                  Pb is BC/10, Pr is RC/Nr, V is Pb*Pb/(Pb+Pr+1e-30)),Vs),
                sort(0,@>=,Vs,Rk), findall(D,member(_-D,Rk),Ds).
gay2 :- ranked(Ds), eras([1,2,4,8,16],Ds,-1000).
eras([K|Ks],Ds,Prev) :-
        eval(K,Ds,M,Q), format("era: top ~w -> median utility ~w iqr ~w~n",[K,M,Q]),
        (M > Prev -> eras(Ks,Ds,M)
        ; format("no gain: stop. keys = previous era~n"), halt).
eras([],_,_) :- halt.

% -- report: find stopping era, then 20 runs at the keys; f1/f2 as Table III ----
pcts(P,F1,F2) :- retractall(label(_,_)), forall(member(D,P),lbl(D,1)), smpl,
        aggregate_all(count,node(_,softgoal),TS),
        aggregate_all(count,topgoal(_),TG0), TG is max(TG0,1),
        aggregate_all(count,(node(S,softgoal),label(S,V),V>0),SS),
        aggregate_all(count,(topgoal(G),label(G,V),V>0),SGl),
        F1 is 100*SS/max(TS,1), F2 is 100*SGl/TG.
bestk([],_,K,_,K).
bestk([K|Ks],Ds,K0,M0,Out) :- eval(K,Ds,M,_),
        (M > M0 -> bestk(Ks,Ds,K,M,Out) ; Out = K0).
report :- ranked(Ds), bestk([1,2,4,8,16],Ds,0,-1000,K), length(P,K), append(P,_,Ds),
        findall(F1-F2,(between(1,20,_),pcts(P,F1,F2)),Rs),
        findall(A,member(A-_,Rs),F1s), findall(B,member(_-B,Rs),F2s),
        median(F1s,M1), iqr(F1s,Q1), median(F2s,M2), iqr(F2s,Q2),
        aggregate_all(count,leaf(_),L), Pct is 100*K/L,
        format("keys=~w/~w (~0f%)  f1: ~1f+-~1f  f2: ~1f+-~1f~n",
               [K,L,Pct,M1,Q1,M2,Q2]), halt.
