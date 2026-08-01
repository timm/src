% nfr3.pl : nfr2.pl without the meta-interpreter. `<--` clauses
% stay in the database as data; a preprocess/0 pass compiles each
% head into real clauses (memo clause first, so loops share a value
% instead of recursing; then believe-head-and-walk-body), and every
% leaf gets a maybe/4 stub. and/or/no and the soft
% contributions (makes/breaks/helps/hurts) are ordinary predicates
% threading a belief list DCG-style, values passed up as an extra
% argument: hard ops are arity 3 (no value: a positive literal
% demands 2), soft ops arity 4. The or-policy is still picked by
% the defining database: any all-hard body makes the head a rule
% node (choice-or, edges dead, as nfr2's agenda cut); else an edge
% node (label ALL bodies, combine). nfr2 parity is exact, including
% its quirk that a hard demand on an edge node is assumed, not
% derived (see the guess clause in nfr2's eval//2).
:- op(1100, xfx, <--).
:- op(900,  fy,  no).
:- dynamic (<--)/2, greedy/0.        % greedy: commit or-choices
:- discontiguous (<--)/2.

permute(Xs,Ys) :- random_permutation(Xs,Ys).

% ---- belief set: a Node-Value list threaded as DCG state -----------------
peek(S,S,S).
push(X,S,[X|S]).
=(X,X,S,S).

believed(K,V,S,S) :-  memberchk(K-V0,S), V = V0.

% maybe(K,V): recall K's value, else assume one (undone on backtrack).
% Callers cut on believed with a FRESH var, unify after: commits to
% the recalled value, then a mismatched demand fails outright.
maybe(K,V,S,S) --> believed(K,W,S,S), !,  V = W.
maybe(K,V) --> { var(V) -> permute([2,-2],Ps), member(V,Ps) ; true }, push(K-V).

% ---- hard side: or//1, and//1, no//1 -------------------------------------
% falsity is assumed, never derived: `no` never runs its node's clauses.
no(K) --> maybe(K,-2).

or(Bs) --> { greedy, !, random_member(B,Bs) }, and(B).       % ISAMP: no retry
or(Bs) --> { permute(Bs,Rs), member(B,Rs) }, and(B).

and(Ls) --> { permute(Ls,Rs) }, ands(Rs).
ands([])     --> [].
ands([L|Ls]) --> lit(L), ands(Ls).

lit(no(K)) --> !, no(K).
lit(K)     --> call(K,2).

% ---- soft side: contributions are nonterminals too -----------------------
makes(X, V)            --> call(X,V).                        % full, same
breaks(X,neg(W))       --> call(X,W).                        % full, flip
helps(X, damp(W))      --> call(X,W).
hurts(X, neg(damp(W))) --> call(X,W).
and(Xs,  amin(Vs))     --> calls(Xs,Vs).
or(Xs,   amax(Vs))     --> calls(Xs,Vs).
no(X,    -2)           --> no(X).              % assume false, contribute -2

calls([],[])         --> [].         % one fold serves edge lists and the
calls([X|Xs],[V|Vs]) --> call(X,V), calls(Xs,Vs).            % and/or args

% contributions arrive symbolic (a loop label may still be a var);
% ground the pendings, then evaluate the expressions.
evalx(X,X)       :- number(X), !.
evalx(neg(E),V)  :- evalx(E,W), V is -W.
evalx(damp(E),V) :- evalx(E,W), V is sign(W)*min(1,abs(W)).
evalx(amin(L),V) :- maplist(evalx,L,Ws), min_list(Ws,V).
evalx(amax(L),V) :- maplist(evalx,L,Ws), max_list(Ws,V).

combine(Vs, V) :- term_variables(Vs, Us), grounds(Us),  % pending loop labels
                  maplist(evalx, Vs, Ws),
                  max_list([0|Ws], P),                 % strongest support,
                  min_list([0|Ws], N),                 % strongest objection
                  \+ (P =:= 2, N =:= -2),              % sat meets denied
                  V is P + N.

grounds([]) :- !.
grounds(Us) :- length(Us,N), N > 3, !,       % big cyclic cluster: punt to
               maplist(=(0),Us).             % undecided, else 5^k guesses
grounds([U|Us]) :- permute([2,1,0,-1,-2],Ps), member(U,Ps),  % unbiased: nfr2
                   grounds(Us).                              % tried 2 first

% ---- compiler ------------------------------------------------------------
% head(K,H,..): K's compiled predicate gets value + threaded state args.
head(K,H,V,S0,S) :- K =.. Ws, append(Ws,[V,S0,S],Zs), H =.. Zs.

softish(makes(_)). softish(breaks(_)). softish(helps(_)).
softish(hurts(_)). softish(and(_)).   softish(or(_)).

hardlit(no(_)) :- !.
hardlit(L)     :- \+ softish(L).
hard(B)        :- maplist(hardlit,B).

wrap(no(X), no(X))  :- !.                    % bare atom in an edge list
wrap(E,     E)      :- softish(E), !.        % is shorthand for makes
wrap(E,     makes(E)).

ref(no(X),    X) :- !.                       % node atoms a body mentions
ref(makes(X), X) :- !.
ref(breaks(X),X) :- !.
ref(helps(X), X) :- !.
ref(hurts(X), X) :- !.
ref(E,        X) :- (E = and(L) ; E = or(L)), !, member(E1,L), ref(E1,X).
ref(X,        X).

compile1(K) :-
  head(K,H,V,S0,S),                          % memo first: cut kills the body
  assertz((H :- believed(K,W,S0,S), !, V = W)),   % clause, so loops share W

  findall(B, (K <-- B), Bs),
  include(hard, Bs, Hs),
  ( Hs = [_|_] -> compile1or(K,Hs) ; compile1and(K,Bs) ).

compile1or(K,Bs) :-                          % any all-hard body: rules win
  head(K,H,2,S0,S),                          % (only ever prove 2); edges on
  assertz((H :- or(Bs,[K-2|S0],S))).         % a mixed head are dead, as nfr2

compile1and(K,Bs) :-                         % edges: V pending for combine;
  append(Bs,Es0), maplist(wrap,Es0,Es),      % a bound-V demand is assumed,
  head(K,H,V,S0,S),                          % never derived (as nfr2's
  assertz((H :- ( var(V)                     % guess clause)
                -> permute(Es,Rs), calls(Rs,Vs,[K-V|S0],S), combine(Vs,V)
                ;  S = [K-V|S0] ))).

stub(K) :- head(K,H,V,S0,S), assertz((H :- maybe(K,V,S0,S))).

% preprocess: run once, after the model is loaded (so discontiguous
% heads see all their bodies). Compiles every head, stubs every
% body atom that has no clauses. After it, the world is closed:
% calling anything else is an existence error -- typos included.
heads(Ks)  :- findall(K, (K <-- _), Ks0), sort(Ks0,Ks).
leaves(Ls) :- heads(Ks),
              findall(X, ((_ <-- B), member(E,B), ref(E,X)), Xs0),
              sort(Xs0,Xs), subtract(Xs,Ks,Ls).

preprocess :- heads(Ks),  maplist(compile1, Ks),
              leaves(Ls), maplist(stub, Ls).

% ---- report --------------------------------------------------------------
% Types are derived from clause shapes, never declared: rule (any
% all-hard body), edge (other clauses), leaf (referenced, no clauses).
type(K,T) :- ( (K <-- B), hard(B) -> T = rule
             ; (K <-- _)          -> T = edge
             ;                       T = leaf ).

types :- heads(Hs), leaves(Ls), append(Hs,Ls,Ks),
         forall(member(T,[rule,edge,leaf]),
                ( findall(K, (member(K,Ks), type(K,T)), Ts),
                  length(Ts,N), format("~w ~w ~q~n",[T,N,Ts]) )).

list_model :- heads(Ks),                     % clause groups per head,
              forall(member(K,Ks),           % a blank line before each
                     ( nl, forall((K <-- B), portray_clause(K <-- B)) )).

% ---- top ----------------------------------------------------------------
abduce(G,As)   :- lit(G,[],A), picks(A,As).
soften(G,V,As) :- call(G,V,[],A), picks(A,As).

picks(A,As) :- msort(A,Ps), findall(X,(member(K-V,Ps),leaf(K,V,X)),As).
leaf(K,_,_)      :- (K <-- _), !, fail.      % derived: hide, show leaves
leaf(K, 2, K)    :- !.
leaf(K,-2, no K) :- !.
leaf(K, V, lab(K,V)).
