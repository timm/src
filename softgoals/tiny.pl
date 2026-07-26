% tiny.pl : smallest slice of re17.pdf figs 3,5,6.
% Edge ops (fig 3): goal on the left, contributors on the right;
% weights makes=1, helps=1/2, hurts=-1/2, breaks=-1.
% Bodies are and/or terms; several clauses with the same head and
% op are an or, assembled at runtime by findall. Everything is
% interpreted -- no goal or term expansion -- so a compiler can be
% added later without changing the model syntax.
% Working memory is an AVL tree in the backtrackable global
% variable seen (b_setval/b_getval): O(log n) lookup, invisible
% state, and the trail restores it on backtracking even past
% cuts. (First choice was assert + undo(retract): undo/1 firing
% mid-unwind segfaults SWI 9.2.9 about 1 run in 6. Avoid.) The
% one store gives memoization (explore a node once), loop
% termination, clash detection (fig 5.3) and the and-undo
% (fig 5.2) for free.
% NB: ~ stands in for minus.
:- op(700, xfx, <++).                            % is made by
:- op(700, xfx, <+).                             % is helped by
:- op(700, xfx, <~).                             % is hurt by
:- op(700, xfx, <~~).                            % is broken by
:- op(650, xfy, or).
:- op(640, xfy, and).
:- op(200, fx, ?).                               % softgoal marker
:- use_module(library(assoc)).
:- dynamic (<++)/2, (<+)/2, (<~)/2, (<~~)/2, (?)/1.
:- discontiguous (<++)/2, (<+)/2, (<~)/2, (<~~)/2.

% model: hard f wants one bundle, small (a,b) or big (c,d,e),
% but e also breaks f; hard g is made by d or e; softgoals p,q
% (marked ?) ride on a and e; a and b help each other, a cycle
% the labeller must survive. Worlds differ with the order tried.
hard(f).  hard(g).
? p.
? q.

a <+  b.                % a loop: a and b help each other
b <+  a.
f <+  a and b.
f <+  c and d and e.
f <~~ e.
g <++ d or e.
p <+  a.
q <++ e.

w(<++, 1.0).  w(<+, 0.5).  w(<~, -0.5).  w(<~~, -1.0).

seen(N,V)    :- b_getval(seen,S), get_assoc(N,S,V).
bassert(N,V) :- b_getval(seen,S0), put_assoc(N,S0,V,S),
                b_setval(seen,S).

% fig 5.1: the label to expect across an edge of weight W.
expect(V,W,E) :- abs(V) =:= 1.0, !, E is W*V.
expect(V,W,V) :- W > 0, !.
expect(V,_,E) :- E is -V.

% fig 5.2: label once; a clash fails, backtracking is the undo.
% One edge group per op; same-head clauses collected as an or.
% A leaf (no edges) may be labelled by fiat; an inner node keeps
% its label only if at least one of its edges could be met.
label(N,V) :- seen(N,V0), !, V0 == V.
label(N,V) :- findall(W-Bs,
                (w(Op,W), findall(B,call(Op,N,B),Bs), Bs\=[]),
                Es0),
              random_permutation(Es0,Es),
              bassert(N,V), edges(Es,V,no-Met),
              (Es == [] -> true ; Met == yes).

% fig 5.3: a contribution edge that cannot be met is ignored.
edges([],_,M-M).
edges([W-Bs|Es],V,M0-M) :- expect(V,W,E),
                           (or(Bs,E) -> M1=yes ; M1=M0),
                           edges(Es,V,M1-M).

% or = one of, random order; and = all of them.
or(Bs,V)        :- random_permutation(Bs,Rs), member(B,Rs),
                   want(B,V).
want(X or Y,V)  :- !, or([X,Y],V).
want(X and Y,V) :- !, want(X,V), want(Y,V).
want(N,V)       :- label(N,V).

% fig 6: the top level is a conjunction of the hard goals (all
% must label satisfied); softgoals are merely attempted. A world
% whose hards clash is thrown away and resampled (retry, not
% backtrack, after Crawford and Baker).
all([]).
all([G|Gs]) :- label(G,1.0), all(Gs).

any([]).
any([G|Gs]) :- (label(G,1.0) -> true ; true), any(Gs).

% one row: X the labels, Y how many softgoals were achieved.
row(X,Y) :- findall(H,hard(H),Hs), findall(P,? P,Ps),
            between(1,100,_),
            empty_assoc(E), b_setval(seen,E),
            random_permutation(Hs,Rs), all(Rs), !,
            any(Ps),
            b_getval(seen,S), assoc_to_list(S,L),
            findall(N=V,member(N-V,L),X),
            aggregate_all(count,(member(P=V,X),? P,V>0),Y).

% ?- row(X,Y).
% X = [a=0.5,b=0.5,d=1.0,e= -1.0,f=1.0,g=1.0,p=1.0], Y = 1
% X = [a=0.5,b=0.5,e=1.0,f=1.0,g=1.0,p=1.0,q=1.0],   Y = 2
