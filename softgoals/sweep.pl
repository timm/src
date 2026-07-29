% sweep.pl : best-seen-after-N random worlds for one model.
% Scores: soft = satisficed softgoals / softgoals (want 1);
% cost = leaves assumed satisfied / leaves (want 0);
% d = sqrt((1-soft)^2 + cost^2)/sqrt(2), 0..1, lower better.
% usage: swipl sweep.pl models/CSServices.pl   (20 repeats of best-of-100)
:- [nfr2].
:- [expand].                          % derives leaf/1, topgoal/1 from node/2
:- assertz(greedy).
:- initialization(main, main).

hards([])     --> [].
hards([H|Hs]) --> eval(H,2), !, hards(Hs).

softs([],K,K)      --> [].
softs([S|Ss],K0,K) --> ( eval(S,V) -> { number(V), V >= 2 -> K1 is K0+1
                                      ; K1 = K0 }
                       ; { K1 = K0 } ),
                       softs(Ss,K1,K).

world(K,D) :- findall(H,topgoal(H),Hs), findall(S,node(S,softgoal),Ss),
              between(1,100,_),
              permute(Hs,Rs), hards(Rs,[],A1), !,
              permute(Ss,Ps), softs(Ps,0,K,A1,A),
              aggregate_all(count,(leaf(L),memberchk(L-2,A)),D).

d(K,D,Dist) :- aggregate_all(count,node(_,softgoal),NS),
               aggregate_all(count,leaf(_),NL),
               S is K/NS, C is D/NL,
               Dist is sqrt((1-S)^2 + C^2)/sqrt(2).

best100(B,SP,CP) :-
        findall(K-D, (between(1,100,_), world(K,D)), Ws),
        findall(Dist-(K-D),(member(K-D,Ws),d(K,D,Dist)),Sc),
        msort(Sc,[B-(BK-BD)|_]),
        aggregate_all(count,node(_,softgoal),NS),
        aggregate_all(count,leaf(_),NL),
        SP is 100*BK/NS, CP is 100*BD/NL.

mean(L,M) :- sum_list(L,S), length(L,N), M is S/N.

main :- set_random(seed(1)), statistics(cputime,T0),
        findall(B-(SP-CP), (between(1,20,_), best100(B,SP,CP)), Rs),
        statistics(cputime,T1), T is T1-T0,
        findall(B,member(B-_,Rs),Bs),       mean(Bs,MB),
        findall(SP,member(_-(SP-_),Rs),SPs), mean(SPs,MS),
        findall(CP,member(_-(_-CP),Rs),CPs), mean(CPs,MC),
        aggregate_all(count,leaf(_),NL),
        format("decisions ~w | ~1fs | mean d ~3f | mean soft ~1f% | mean cost ~1f%~n",
               [NL,T,MB,MS,MC]).
