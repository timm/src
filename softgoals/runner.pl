% runner.pl : seeded softgoal-coverage sweep for any models/*.pl.
% usage: swipl runner.pl models/CSServices.pl   (both get consulted)
:- ['tiny.pl'].
:- initialization(main, main).

w2op( 1.0, <++).
w2op( 0.5, <+ ).
w2op(-0.5, <~ ).
w2op(-1.0, <~~).

load :- retractall(_ <++ _), retractall(_ <+ _),      % drop tiny's toy model
        retractall(_ <~ _), retractall(_ <~~ _), retractall(? _),
        forall(edge(C,P,W),
               (W1 is float(W), w2op(W1,Op), T =.. [Op,P,C], assertz(T))),
        forall(node(S,softgoal), assertz(? S)),
        abolish(hard/1),                       % model declares its roots:
        assertz((hard(T) :- topgoal(T))).      % trust topgoal/1, not shape

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
