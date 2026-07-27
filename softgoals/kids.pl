% kids.pl : run tiny.pl's labeller on the paper's smallest i* model
% (KidsandYouth, 81 nodes 81 edges), seed 1, 20 staggered worlds.
:- ['tiny.pl'].
:- ['models/KidsandYouth.pl'].
:- initialization(main, main).

w2op( 1.0, <++).
w2op( 0.5, <+ ).
w2op(-0.5, <~ ).

load :- retractall(_ <++ _), retractall(_ <+ _),      % drop tiny's toy model
        retractall(_ <~ _), retractall(_ <~~ _), retractall(? _),
        forall(edge(C,P,W),
               (W1 is float(W), w2op(W1,Op), T =.. [Op,P,C], assertz(T))),
        forall(node(S,softgoal), assertz(? S)),
        abolish(hard/1),                       % model declares its roots:
        assertz((hard(T) :- topgoal(T))).      % trust topgoal/1, not shape

main :- set_random(seed(1)), load,
        setof(H,hard(H),Hs), length(Hs,NH),
        aggregate_all(count, ? _, NS),
        format("hard goals ~w, softgoals ~w~n",[NH,NS]),
        forall(between(1,20,I),
               ( row(_,Y) -> format("run ~w: ~w/~w soft~n",[I,Y,NS])
               ; format("run ~w: no world~n",[I]) )).
