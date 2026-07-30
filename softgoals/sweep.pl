% sweep.pl : best-seen-after-N random worlds for one model.
% Scores: soft = satisficed softgoals / softgoals (want 1);
% cost = leaves assumed satisfied / leaves (want 0);
% d = sqrt((1-soft)^2 + cost^2)/sqrt(2), 0..1, lower better.
% usage: swipl sweep.pl models/CSServices.pl   (20 repeats of best-of-100)
:- [nfr3].
:- assertz(greedy).
:- initialization(main, main).

hardgoals(Hs) :- (goals(hard) <-- Hs), !.
hardgoals([]).
softgoals(Ss) :- (goals(soft) <-- [or(Ss)]), !.
softgoals([]).

hards([])     --> [].
hards([H|Hs]) --> lit(H), !, hards(Hs).

softs([],K,K)      --> [].
softs([S|Ss],K0,K) --> ( call(S,V) -> { number(V), V >= 2 -> K1 is K0+1
                                      ; K1 = K0 }
                       ; { K1 = K0 } ),
                       softs(Ss,K1,K).

world(K,D) :- hardgoals(Hs), softgoals(Ss),
              between(1,100,_),
              permute(Hs,Rs), hards(Rs,[],A1), !,
              permute(Ss,Ps), softs(Ps,0,K,A1,A),
              leaves(Ls),
              aggregate_all(count,(member(L,Ls),memberchk(L-2,A)),D).

d(K,D,Dist) :- softgoals(Ss), length(Ss,NS0), NS is max(1,NS0),
               leaves(Ls),    length(Ls,NL0), NL is max(1,NL0),
               S is K/NS, C is D/NL,
               Dist is sqrt((1-S)^2 + C^2)/sqrt(2).

best100(B,SP,CP) :-
        findall(K-D, (between(1,100,_), world(K,D)), Ws),
        findall(Dist-(K-D),(member(K-D,Ws),d(K,D,Dist)),Sc),
        msort(Sc,[B-(BK-BD)|_]),
        softgoals(Ss), length(Ss,NS0), NS is max(1,NS0),
        leaves(Ls),    length(Ls,NL0), NL is max(1,NL0),
        SP is 100*BK/NS, CP is 100*BD/NL.

mean(L,M) :- sum_list(L,S), length(L,N), M is S/N.

main :- preprocess,
        set_random(seed(1)), statistics(cputime,T0),
        findall(B-(SP-CP), (between(1,20,_), best100(B,SP,CP)), Rs),
        statistics(cputime,T1), T is T1-T0,
        findall(B,member(B-_,Rs),Bs),       mean(Bs,MB),
        findall(SP,member(_-(SP-_),Rs),SPs), mean(SPs,MS),
        findall(CP,member(_-(_-CP),Rs),CPs), mean(CPs,MC),
        leaves(Ls), length(Ls,NL),
        format("decisions ~w | ~1fs | mean d ~3f | mean soft ~1f% | mean cost ~1f%~n",
               [NL,T,MB,MS,MC]).
