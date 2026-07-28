% runner2.pl : seeded softgoal-coverage sweep on the nfr2 engine.
% usage: swipl runner2.pl models/CSServices.pl  (both get consulted)
% One world: believe every topgoal satisficed (Horn side, top-down,
% choice-or; leaves abduced +-2 at random = the stagger), then
% evaluate each softgoal bottom-up (contributions fold through
% combine). strict = fully satisficed only (V >= 2); lenient V > 0.
:- ['nfr2.pl'].
:- assertz(greedy).                    % ISAMP: restart beats backtrack
:- initialization(main, main).

hards([])     --> [].
hards([H|Hs]) --> eval(H,2), !, hards(Hs).  % commit per goal; bad worlds
                                            % die fast, the retry restarts

softs([],K,K,_)         --> [].
softs([S|Ss],K0,K,Thr)  --> ( eval(S,V) -> { V >= Thr -> K1 is K0+1 ; K1 = K0 }
                            ; { K1 = K0 } ),
                            softs(Ss,K1,K,Thr).

row(Thr,K) :- findall(H,topgoal(H),Hs), findall(S,node(S,softgoal),Ss),
              between(1,100,_),
              permute(Hs,Rs), hards(Rs,[],A1), !,
              permute(Ss,Ps), softs(Ps,0,K,Thr,A1,_).

main :- N = 1000,
        set_random(seed(1)),
        aggregate_all(count, node(_,softgoal), NS),
        aggregate_all(count, topgoal(_), NH),
        findall(K, (between(1,N,_), row(2,K)), Ks),
        msort(Ks,S), length(S,Got),
        ( Got =:= 0 -> format("no worlds~n")
        ; min_list(S,Lo), max_list(S,Hi), I is max(1,Got//2), nth1(I,S,Md),
          PL is 100*Lo/NS, PM is 100*Md/NS, PH is 100*Hi/NS,
          format("hard ~w soft ~w | ~w/~w worlds | strict soft% min ~1f med ~1f max ~1f~n",
                 [NH,NS,Got,N,PL,PM,PH]) ).
