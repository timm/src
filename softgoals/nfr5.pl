:- op(1001,xfx,<--).
:- multifile (<--)/2.
:- dynamic (<--)/2.
:- discontiguous (<--)/2.

any(Xs,X)      :- length(Xs,N), I is random(N), nth0(I,Xs,X).
all([],[]).
all(Xs,[Y|Ys]) :- any(Xs,Y), selectchk(Y,Xs,Zs), all(Zs,Ys).

how(X=V,      chk(Z,V), L) :- memberchk(X=Z,L).
how(X=V,      add(X=V), _).
how([],       [],       _).
how([H|T],    [H|T],    _).
how(and(Xs),  Ys,       _) :- all(Xs,Ys).
how(or(Xs),   [X],      _) :- any(Xs,X).
how(makes(X), [X=t],    _).
how(breaks(X),[X=f],    _).
how(helps(X), [X=V],    _) :- any([t,t,f],V).
how(hurts(X), [X=V],    _) :- any([f,f,t],V).
how(must(X),  [X, X=t], _).   % hard goal: derive it, then insist
how(X,        [],       L) :- memberchk(X=_,L).
how(X,        (X <-- [B|Bs]),_) :- findall(B0, (X <-- B0),[B|Bs]).
how(X,        add(X=t), _) :- atom(X).

isamp1([],         L, L).
isamp1(chk(V,V),   L, L).
isamp1(add(B),     L, [B|L]).
isamp1([H|T],      L0,L) :- isamp(H,L0,L1), isamp(T,L1,L).
isamp1((X <-- Bs), L0,L) :-
  ( isamp(or(Bs),[X=t|L0],L) -> true ; atom(X), L = [X=f|L0] ).

isamp(X,L0,L) :- once(how(X,W,L0)), isamp1(W,L0,L).
