% runner4.pl : runner3.pl on the nfr4 engine (database beliefs).
% usage: swipl runner4.pl models/CSServices.pl  (both get consulted)
% One world: reset the seen/2 table, believe every hard goal
% satisficed, then evaluate each softgoal; a softgoal that fails
% rolls its beliefs back through learn/2's retract-on-backtrack.
:- [nfr4].
:- assertz(greedy).
:- initialization(main, main).

hardgoals(Hs) :- (goals(hard) <-- Hs), !.
hardgoals([]).
softgoals(Ss) :- (goals(soft) <-- [or(Ss)]), !.
softgoals([]).

hards([]).
hards([H|Hs]) :- lit(H,[]), !, hards(Hs).   % commit per goal; bad worlds
                                            % die fast, the retry restarts
softs([],K,K,_).
softs([S|Ss],K0,K,Thr) :- ( ev(S,V,[]) -> ( V >= Thr -> K1 is K0+1
                                          ; K1 = K0 )
                          ; K1 = K0 ),
                          softs(Ss,K1,K,Thr).

row(Thr,K) :- hardgoals(Hs), softgoals(Ss),
              between(1,100,_),
              reset, permute(Hs,Rs), hards(Rs), !,
              permute(Ss,Ps), softs(Ps,0,K,Thr).

main :- preprocess,
        N = 1000,
        set_random(seed(1)),
        softgoals(Ss), length(Ss,NS0), NS is max(1,NS0),  % SD-only: no softgoals
        hardgoals(Hs), length(Hs,NH),
        findall(K, (between(1,N,_), row(2,K)), Ks),
        msort(Ks,S), length(S,Got),
        ( Got =:= 0 -> format("no worlds~n")
        ; min_list(S,Lo), max_list(S,Hi), I is max(1,Got//2), nth1(I,S,Md),
          PL is 100*Lo/NS, PM is 100*Md/NS, PH is 100*Hi/NS,
          format("hard ~w soft ~w | ~w/~w worlds | strict soft% min ~1f med ~1f max ~1f~n",
                 [NH,NS0,Got,N,PL,PM,PH]) ).
