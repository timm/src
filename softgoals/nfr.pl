% nfr.pl : abductive meta-interpreter, propositional horn + NFR softgoals.
% literals : a | not a          rules : Head <- [Lit,...]      fact : H <- []
% edges    : G <~ [make(X),break(X),help(X),hurt(X),and([..]),or([..]),task(P)]
% labels   : 2=satisficed 1=weak+ 0=undecided -1=weak- -2=denied
:- op(900, fy, not).
:- op(1100, xfx, <-).
:- op(1100, xfx, <~).
:- dynamic (<-)/2, (<~)/2.
:- discontiguous (<-)/2, (<~)/2.

% ---- belief set: assoc-list threaded invisibly as DCG state --------------
kv(not X,    X,       no) :- !.
kv(lab(G,V), soft(G), V)  :- !.
kv(busy(G),  busy(G), t)  :- !.
kv(X,        X,       yes).

peek(A,A,A).
push(X,A,[X|A]).

believed(X) --> peek(A), { kv(X,K,V), memberchk(K-V1,A), V = V1 }.

believe(X)  --> peek(A0), { kv(X,K,V) },       % memberchk = member + cut
                ( { memberchk(K-V1,A0) } -> { V1 == V }
                ; push(K-V) ).

% ---- horn proof ---------------------------------------------------------
prove(L)  --> believed(L), !.                  % loop, or old news: visit once
prove(L)  --> { findall(B, (L <- B), Bs), Bs \= [] }, !,
              believe(L),                      % head first, so loops close
              { random_permutation(Bs, Rs),  member(Body, Rs),       % ors
                random_permutation(Body, Ls) }, proves(Ls).          % ands
prove(L)  --> believe(L).                      % no rules: assume it

proves([])     --> [].
proves([L|Ls]) --> prove(L), proves(Ls).

% ---- softgoal propagation -----------------------------------------------
soft(G,V) --> believed(lab(G,W)), !, { V=W }.
soft(G,V) --> believed(busy(G)), !, { V=0 }.   % in a loop: visit once
soft(G,V) --> { findall(E, ((G <~ Es), member(E,Es)), Edges), Edges \= [] }, !,
              believe(busy(G)), { random_permutation(Edges, Rs) },
              foldl(contrib, Rs, Vs), { combine(Vs, V) },
              believe(lab(G,V)).
soft(G,V) --> { random_permutation([2,-2], Ps), member(V,Ps) },  % abducible
              believe(lab(G,V)).

contrib(make(X), V) --> soft(X,V).                                % full, same
contrib(break(X),V) --> soft(X,W), { V is -W }.                   % full, flip
contrib(help(X), V) --> soft(X,W), { V is  sign(W)*min(1,abs(W)) }.
contrib(hurt(X), V) --> soft(X,W), { V is -sign(W)*min(1,abs(W)) }.
contrib(and(Xs), V) --> foldl(soft,Xs,Vs), { min_list(Vs,V) }.
contrib(or(Xs),  V) --> foldl(soft,Xs,Vs), { max_list(Vs,V) }.
contrib(task(P), V) --> prove(P), { V=2 }.             % bridge to horn side

combine(Vs, V) :- include([X]>>(X>0), Vs, Ps), include([X]>>(X<0), Vs, Ns),
                  ( Ps=[] -> P=0 ; max_list(Ps,P) ),
                  ( Ns=[] -> N=0 ; min_list(Ns,N) ),
                  \+ (P =:= 2, N =:= -2),              % sat meets denied
                  V is max(-2, min(2, P+N)).

% ---- top ----------------------------------------------------------------
abduce(G,As)   :- prove(G,[],A), picks(A,As).
soften(G,V,As) :- soft(G,V,[],A), picks(A,As).

picks(A,As) :- msort(A,Ps), findall(X,(member(K-V,Ps),leaf(K,V,X)),As).
leaf(busy(_), _, _)        :- !, fail.
leaf(soft(G), V, lab(G,V)) :- !, \+ (G <~ _).
leaf(P, yes, P)            :- \+ (P <- _).
leaf(P, no,  not P)        :- \+ (P <- _).
