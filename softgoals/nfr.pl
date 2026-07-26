% nfr.pl : abductive meta-interpreter, propositional horn + NFR softgoals.
% literals : a | not a          rules : Head <- [Lit,...]      fact : H <- []
% edges    : G <~ [make(X),break(X),help(X),hurt(X),and([..]),or([..]),task(P)]
% labels   : 2=satisficed 1=weak+ 0=undecided -1=weak- -2=denied
:- op(900, fy, not).
:- op(1100, xfx, <-).
:- op(1100, xfx, <~).
:- dynamic (<-)/2, (<~)/2.
:- discontiguous (<-)/2, (<~)/2.

% ---- belief set: threaded assoc-list, one value per key ------------------
kv(not X,    X,       no) :- !.
kv(lab(G,V), soft(G), V)  :- !.
kv(busy(G),  busy(G), t)  :- !.
kv(X,        X,       yes).

believed(X,A) :- kv(X,K,V), memberchk(K-V1,A), V = V1.

believe(X,A0,A) :- kv(X,K,V),                  % memberchk = member + cut
                   ( memberchk(K-V1,A0) -> V1 == V, A = A0
                   ; A = [K-V|A0] ).

% ---- horn proof ---------------------------------------------------------
prove(L,A,A)   :- believed(L,A), !.            % loop, or old news: visit once
prove(L,A0,A)  :- findall(B, (L <- B), Bs), Bs \= [], !,
                  believe(L,A0,A1),            % head first, so loops close
                  random_permutation(Bs, Rs),  member(Body, Rs),     % ors
                  random_permutation(Body, Ls), proves(Ls,A1,A).     % ands
prove(L,A0,A)  :- believe(L,A0,A).             % no rules: assume it

proves([],A,A).
proves([L|Ls],A0,A) :- prove(L,A0,A1), proves(Ls,A1,A).

% ---- softgoal propagation -----------------------------------------------
soft(G,V,A,A)  :- believed(lab(G,W),A), !, V=W.
soft(G,V,A,A)  :- believed(busy(G),A), !, V=0. % in a loop: visit once
soft(G,V,A0,A) :- findall(E, ((G <~ Es), member(E,Es)), Edges), Edges \= [], !,
                  believe(busy(G),A0,A1), random_permutation(Edges, Rs),
                  foldl(contrib, Rs, Vs, A1, A2), combine(Vs, V),
                  believe(lab(G,V),A2,A).
soft(G,V,A0,A) :- random_permutation([2,-2], Ps), member(V,Ps),  % abducible
                  believe(lab(G,V),A0,A).

contrib(make(X), V,A0,A) :- soft(X,V,A0,A).                       % full, same
contrib(break(X),V,A0,A) :- soft(X,W,A0,A), V is -W.              % full, flip
contrib(help(X), V,A0,A) :- soft(X,W,A0,A), V is  sign(W)*min(1,abs(W)).
contrib(hurt(X), V,A0,A) :- soft(X,W,A0,A), V is -sign(W)*min(1,abs(W)).
contrib(and(Xs), V,A0,A) :- foldl(soft,Xs,Vs,A0,A), min_list(Vs,V).
contrib(or(Xs),  V,A0,A) :- foldl(soft,Xs,Vs,A0,A), max_list(Vs,V).
contrib(task(P), V,A0,A) :- prove(P,A0,A), V=2.        % bridge to horn side

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
