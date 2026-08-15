:- op(1001,xfx,<--).
:- multifile (<--)/2.
:- dynamic (<--)/2.
:- discontiguous (<--)/2.

any(Xs,X) :- length(Xs,N), I is random(N), nth0(I,Xs,X).

many([],[]).
many(Xs,[Y|Ys]) :-any(Xs,Y), selectchk(Y,Xs,Zs), many(Zs,Ys).

todo(X=V,      chk(V,W), L) :- memberchk(X=W,L).
todo(X=V,      add(X=V), _).
todo([],       [],       _).
todo([H|T],    [H|T],    _).
todo(and(Xs),  Ys,       _) :- many(Xs,Ys).
todo(X,        [],       L) :- memberchk(replay=on,L), believed(L,X).
todo(or(Xs),   [X],      L) :- memberchk(replay=on,L), member(X,Xs), believed(L,X).
todo(or(Xs),   [X],      _) :- any(Xs,X).
todo(makes(X), [X=t],    _).
todo(breaks(X),[X=f],    _).
todo(helps(X), [X=V],    _) :- any([t,t,f],V).
todo(hurts(X), [X=V],    _) :- any([f,f,t],V).
todo(X,        [],       L) :- memberchk(X=_,L).
todo(X,        (X <-- [B|Bs]),_) :- findall(B0, (X <-- B0),[B|Bs]).
todo(X,        add(X=t), _) :- atom(X).

do([],         L, L).
do(chk(V,V),   L, L).
do(add(B),     L, [B|L]).
do([H|T],      L0,L) :- isamp(H,L0,L1), isamp(T,L1,L).
do((X <-- Bs), L0,L) :-
  ( isamp(or(Bs),[X=t|L0],L) -> true ; atom(X), L = [X=f|L0] ).

believed(L,X) :- \+ (sym(X,A), \+ memberchk(A=_,L)).

isamp(X,L0,L) :- todo(X,W,L0), !, do(W,L0,L).

% ---- static sorts, derived from clause shape (never run by isamp)
sym(X,X) :- atom(X), \+ memberchk(X,[t,f]).
sym(T,X) :- compound(T), T =.. [_|As], member(A,As), sym(A,X).

head(X)     :- (X <-- _).
target(X)   :- (_ <-- B), member(E,B),
               member(E,[makes(X),breaks(X),helps(X),hurts(X)]).
quality(X)  :- target(X), \+ head(X).

eq(X=_,  X).
eq(T,    X) :- compound(T), T =.. [_|As], member(A,As), eq(A,X).
demanded(X) :- (_ <-- B), eq(B,X).

mentions(Xs):- setof(X, H^B^((H <-- B), (sym(H,X);sym(B,X))), Xs).
typo(X)     :- mentions(Xs), member(X,Xs),
               \+ head(X), \+ target(X), \+ demanded(X).

lint :- forall(typo(X), format("lint: undefined, unlinked: ~w~n",[X])).

% ---- scoring: prep once per model, then score many worlds -------
% score(Prep, World, score(Benefit,Footprint,Slack)):
%   benefit   = qualities labeled t        (maximize)
%   footprint = leaf assumptions bought    (minimize)
%   slack     = atoms never touched        (diagnostic, not objective)
prep(prep(Qs,Ls,N)) :-
  mentions(Xs), length(Xs,N),
  findall(Q, (member(Q,Xs), once(quality(Q))), Qs),
  findall(F, (member(F,Xs), \+ head(F), \+ memberchk(F,Qs)), Ls).

score(prep(Qs,Ls,N), World, score(B,F,S)) :-
  count(Qs,World,B), count(Ls,World,F),
  length(World,W), S is N - W.

count(Xs,World,N) :-
  aggregate_all(count, (member(X,Xs), memberchk(X=t,World)), N).

% running min/max of scores, and distance to heaven (B up, F down)
mm0(mm(inf,-inf, inf,-inf, inf,-inf)).
mmadd(score(B,F,S), mm(B0,B1,F0,F1,S0,S1), mm(B2,B3,F2,F3,S2,S3)) :-
  B2 is min(B0,B), B3 is max(B1,B), F2 is min(F0,F), F3 is max(F1,F),
  S2 is min(S0,S), S3 is max(S1,S).

norm(Lo,Hi,_,0.5) :- Hi =< Lo, !.
norm(Lo,Hi,X,N)   :- N is (X-Lo)/(Hi-Lo+1e-32).

d2h(mm(B0,B1,F0,F1,_,_), score(B,F,_), D) :-
  norm(B0,B1,B,NB), norm(F0,F1,F,NF),
  D is sqrt(((1-NB)**2 + NF**2)/2).
