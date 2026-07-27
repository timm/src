% nfr2.pl : nfr.pl with prove and soft merged into one eval//2.
% The or-policy is picked by the defining database, not a flag:
% rules (H <- Body) give choice-or (commit to one body, minimal
% assumptions); edges (G <~ Es) give max-or (label all, combine).
% Horn is the 5-valued algebra restricted to {2,-2}: a literal L
% demands its kv target exactly; believing the head IS the value.
:- op(900, fy, not).
:- op(1100, xfx, <-).
:- op(1100, xfx, <~).
:- dynamic (<-)/2, (<~)/2.
:- discontiguous (<-)/2, (<~)/2.

% ---- belief set: Node-Value list threaded as DCG state -------------------
kv(not X, X, -2) :- !.
kv(X,     X,  2).

peek(A,A,A).
push(X,A,[X|A]).

believed(K,V) --> peek(A), { memberchk(K-V1,A), V = V1 }.
believe(K,V)  --> peek(A0),
                  ( { memberchk(K-V1,A0) } -> { V1 == V }
                  ; push(K-V) ).

% ---- one evaluator -------------------------------------------------------
eval(K,V) --> believed(K,W), !, { V = W }.     % memo, or a loop: share V
eval(K,V) --> { agenda(K,V,How,Xs) }, !,       % the stuff to prove...
              believe(K,V),                    % (head first: rules close true,
              { random_permutation(Xs,Rs) },   %  edge loops share pending V)
              walk(How,Rs,V).                  % ...walked in random order
eval(K,V) --> ( { var(V) } -> { random_permutation([2,-2],Ps), member(V,Ps) }
              ; [] ),
              believe(K,V).                    % bare leaf: assume it

% agenda head carries the value contract: rules only ever prove 2,
% so a -2 target fails here by unification (falsity is assumed,
% never derived); edges leave V pending for combine.
agenda(K,2,or,Bs)    :- findall(B, (K <- B), Bs), Bs \= [].
agenda(K,_,edges,Es) :- findall(E, ((K <~ Es0), member(E,Es0)), Es), Es \= [].

walk(or,Bs,_)  --> { member(B,Bs),             % or: do ONE of them
                     random_permutation(B,Ls) },
                   lits(Ls).
walk(and,Es,V) --> foldl(contrib,Es,Vs),       % and: do ALL of them
                   { combine(Vs,V) }.

lits([])     --> [].
lits([L|Ls]) --> { kv(L,K,T) }, eval(K,T), lits(Ls).

% ---- contributions -------------------------------------------------------
contrib(make(X), V) --> eval(X,V).                                % full, same
contrib(break(X),V) --> eval(X,W), { V is -W }.                   % full, flip
contrib(help(X), V) --> eval(X,W), { V is  sign(W)*min(1,abs(W)) }.
contrib(hurt(X), V) --> eval(X,W), { V is -sign(W)*min(1,abs(W)) }.
contrib(and(Xs), V) --> foldl(eval,Xs,Vs), { min_list(Vs,V) }.
contrib(or(Xs),  V) --> foldl(eval,Xs,Vs), { max_list(Vs,V) }.
contrib(task(P), V) --> lits([P]), { V = 2 }.          % bridge to horn side

combine(Vs, V) :- term_variables(Vs, Us), grounds(Us),  % pending loop labels
                  include([X]>>(X>0), Vs, Ps), include([X]>>(X<0), Vs, Ns),
                  ( Ps=[] -> P=0 ; max_list(Ps,P) ),
                  ( Ns=[] -> N=0 ; min_list(Ns,N) ),
                  \+ (P =:= 2, N =:= -2),              % sat meets denied
                  V is max(-2, min(2, P+N)).

grounds([]).
grounds([U|Us]) :- member(U, [2,1,0,-1,-2]), grounds(Us).

% ---- top ----------------------------------------------------------------
abduce(G,As)   :- kv(G,K,T), eval(K,T,[],A), picks(A,As).
soften(G,V,As) :- eval(G,V,[],A), picks(A,As).

picks(A,As) :- msort(A,Ps), findall(X,(member(K-V,Ps),leaf(K,V,X)),As).
leaf(K,_,_)        :- (K <- _), !, fail.       % derived: hide, show leaves
leaf(K,_,_)        :- (K <~ _), !, fail.
leaf(K, 2, K)      :- !.
leaf(K,-2, not K)  :- !.
leaf(K, V, lab(K,V)).
