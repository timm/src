% loadmodel.pl : map a models/*.pl fact base onto tiny.pl clauses.
% Contributions (edge/3) become weighted ops. Structure becomes one
% <++ body per parent: dependencies and and-decompositions are
% conjuncts, or-decompositions an inner or-group -- matching the
% reference propagate(), where deps are mandatory and or picks one.
:- dynamic node/2, edge/3, dep/2, dec/3, leaf/1, topgoal/1.

w2op( 1.0, <++).
w2op( 0.5, <+ ).
w2op(-0.5, <~ ).
w2op(-1.0, <~~).

orify([X],X) :- !.
orify([X|Xs],X or R) :- orify(Xs,R).
andify([X],X) :- !.
andify([X|Xs],X and R) :- andify(Xs,R).

struct(P) :- findall(D, dep(D,P), Ds),
             findall(K, dec(K,P,and), As),
             findall(K, dec(K,P,or), Ks),
             ( Ks = [] -> Or = [] ; orify(Ks,O), Or = [O] ),
             append(Ds,As,DA), append(DA,Or,Parts),
             ( Parts = [] -> true
             ; andify(Parts,B), assertz(P <++ B) ).

load :- retractall(_ <++ _), retractall(_ <+ _),      % drop tiny's toy model
        retractall(_ <~ _), retractall(_ <~~ _), retractall(? _),
        forall(edge(C,P,W),
               (W1 is float(W), w2op(W1,Op), T =.. [Op,P,C], assertz(T))),
        forall(node(S,softgoal), assertz(? S)),
        ( setof(P, kid(P), Ps) -> forall(member(P,Ps), struct(P)) ; true ),
        abolish(hard/1),                       % model declares its roots:
        assertz((hard(T) :- topgoal(T))).      % trust topgoal/1, not shape

kid(P) :- dep(_,P).
kid(P) :- dec(_,P,_).
