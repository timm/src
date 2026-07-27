% runner.pl : seeded softgoal-coverage sweep for any models/*.pl.
% usage: swipl runner.pl models/CSServices.pl   (both get consulted)
:- ['tiny.pl'].
:- ['loadmodel.pl'].
:- initialization(main, main).

main :- N = 100,
        set_random(seed(1)), load,
        aggregate_all(count, ? _, NS),
        setof(H,hard(H),Hs), length(Hs,NH),
        findall(Y, (between(1,N,_), row(_,Y)), Ys),
        msort(Ys,S), length(Ys,Got),
        ( Got =:= 0 -> format("no worlds~n")
        ; min_list(S,Lo), max_list(S,Hi),
          length(S,L), I is max(1,L//2), nth1(I,S,Med),
          Pc is 100*Med/NS,
          format("hard ~w soft ~w | ~w worlds of ~w | min ~w med ~w max ~w | median ~1f%~n",
                 [NH,NS,Got,N,Lo,Med,Hi,Pc]) ).
