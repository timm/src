% nfr2.pl : nfr.pl with prove and soft merged into one eval//2.
% The or-policy is picked by the defining database, not a flag:
% rules (H <- Body) give choice-or (commit to one body, minimal
% assumptions); edges (G <~ Es) give max-or (label all, combine).
% Horn is the 5-valued algebra restricted to {2,-2}: a literal L
% demands its kv target exactly; believing the head IS the value.
:- op(900, fy, not).
:- op(1100, xfx, <-).
:- op(1100, xfx, <~).
:- dynamic (<-)/2, (<~)/2, greedy/0.   % greedy: commit or-choices
:- discontiguous (<-)/2, (<~)/2.

% ==== engine: stochastic abduction over a belief list ====================
% needs from domain: kv/3, agenda/4, contrib//2, combine/2.
% contract: or-agendas arrive with V bound (the kv target); and-agendas
% leave V unbound so loops close on the shared pending variable.

permute(Xs,Ys) :- random_permutation(Xs,Ys).

% ---- belief set: Node-Value list threaded as DCG state -------------------
peek(A,A,A).
push(X,A,[X|A]).

believed(K,V) --> peek(A),   { memberchk(K-V1,A), V = V1 }.
believe(K,V)  --> peek(A0), ({ memberchk(K-V1,A0) } -> { V1==V } ; push(K-V)).

% ---- one evaluator -------------------------------------------------------
eval(K,V) --> believed(K,W), !, { V = W }.     % memo, or a loop: share V
eval(K,V) --> { agenda(K,V,How,Xs) }, !,       % the stuff to prove...
              believe(K,V),                    % (head first: rules close true,
              { permute(Xs,Rs) },   %  edge loops share pending V)
              walk(How,Rs,V).                  % ...walked in random order
eval(K,V) --> ({var(V)} -> {permute([2,-2],Ps), member(V,Ps)} ; [] ),
              believe(K,V).

walk(or,Bs,_)  --> { greedy, !, random_member(B,Bs), permute(B,Ls) },
                   lits(Ls).                   % ISAMP mode: no or-retry
walk(or,Bs,_)  --> { member(B,Bs), permute(B,Ls) }, lits(Ls).
walk(and,Es,V) --> foldl(contrib,Es,Vs), { combine(Vs,V) }.

lits([])     --> [].
lits([L|Ls]) --> { kv(L,K,T) }, eval(K,T), lits(Ls).

% ==== domain: NFR 5-valued algebra + the <-/<~ policy ====================

kv(not X, X, -2) :- !.
kv(X,     X,  2).

% agenda head carries the value contract: rules only ever prove 2,
% so a -2 target fails here by unification (falsity is assumed,
% never derived); edges leave V pending for combine.
agenda(K,2,or,Bs)  :- findall(B, (K <- B), Bs), Bs \= [].
agenda(K,V,and,Es) :- var(V), findall(E, ((K <~ Es0), member(E,Es0)), Es), Es \= [].

% ---- contributions -------------------------------------------------------
contrib(make(X), V) --> eval(X,V).                                % full, same
contrib(break(X),V) --> eval(X,W), { V = neg(W) }.        % full, flip
contrib(help(X), V) --> eval(X,W), { V = damp(W) }.
contrib(hurt(X), V) --> eval(X,W), { V = neg(damp(W)) }.
contrib(and(Xs), V) --> foldl(eval,Xs,Vs), { V = amin(Vs) }.
contrib(or(Xs),  V) --> foldl(eval,Xs,Vs), { V = amax(Vs) }.
contrib(task(P), V) --> lits([P]), { V = 2 }.          % bridge to horn side

% contributions arrive symbolic (a loop label may still be a var);
% ground the pendings, then evaluate the expressions.
evalx(X,X)       :- number(X), !.
evalx(neg(E),V)  :- evalx(E,W), V is -W.
evalx(damp(E),V) :- evalx(E,W), V is sign(W)*min(1,abs(W)).
evalx(amin(L),V) :- maplist(evalx,L,Ws), min_list(Ws,V).
evalx(amax(L),V) :- maplist(evalx,L,Ws), max_list(Ws,V).

combine(Vs, V) :- term_variables(Vs, Us), grounds(Us),  % pending loop labels
                  maplist(evalx, Vs, Ws),
                  include([X]>>(X>0), Ws, Ps), include([X]>>(X<0), Ws, Ns),
                  ( Ps=[] -> P=0 ; max_list(Ps,P) ),
                  ( Ns=[] -> N=0 ; min_list(Ns,N) ),
                  \+ (P =:= 2, N =:= -2),              % sat meets denied
                  V is max(-2, min(2, P+N)).

grounds([]) :- !.
grounds(Us) :- length(Us,N), N > 3, !,       % big cyclic cluster: punt to
               maplist(=(0),Us).             % undecided, else 5^k guesses
grounds([U|Us]) :- member(U, [2,1,0,-1,-2]), grounds(Us).

% ==== top ================================================================
abduce(G,As)   :- kv(G,K,T), eval(K,T,[],A), picks(A,As).
soften(G,V,As) :- eval(G,V,[],A), picks(A,As).

picks(A,As) :- msort(A,Ps), findall(X,(member(K-V,Ps),leaf(K,V,X)),As).
leaf(K,_,_)        :- (K <- _), !, fail.       % derived: hide, show leaves
leaf(K,_,_)        :- (K <~ _), !, fail.
leaf(K, 2, K)      :- !.
leaf(K,-2, not K)  :- !.
leaf(K, V, lab(K,V)).
