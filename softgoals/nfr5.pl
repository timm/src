:- op(1001,xfx,<--).
:- discontiguous (<--)/2.

permute(Xs,Ys) :- random_permutation(Xs,Ys).

klauses(Head, Tails) :-
  findall(Head/B, (Head <-- B), Pairs),
  permute(Pairs, Tails).

\+(X,Y,L,L) :- \+ member(X=Y,L).

=(X,Y,L0,L0) :- member(X=Z,L0), !, Y=Z.
=(X,Y,L,[X=Y|L]).

prove(X=Y)        --> X=Y.
prove(not(X=Y))   --> \+(X,Y).
prove(and(L))     --> {permute(L,L1)}, prove(all(L1)).
prove(or(L))      --> {permute(L,L1), member(X,L1)}, prove(X).
prove(all([]))    --> [].
prove(all([H|T])) --> prove(H), prove(all(T)).
prove(X)          --> {klauses(X,Ys), member(X/B,Ys)}, prove(B).
