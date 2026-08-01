% nfr4.pl : nfr3.pl with the belief list swapped for the clause
% database. seen(K,V) facts are first-arg indexed, so recall is
% O(1) where memberchk was O(|beliefs|); a world begins with
% retractall(seen(_,_)). learn/2 is the classic backtrackable
% assert (assertz ; retract-then-fail), so enumeration and the
% drivers' failure-rollback still undo beliefs correctly.
% assertz copies terms, so nfr3's shared pending variables
% cannot live in the database: instead loops are caught by a
% downward path argument (memberchk there is bounded by graph
% depth, not belief count) and a looped node's label is guessed
% on the spot, 5-wide; its own combine verifies the guess
% against the computed label, else the world fails. Everything
% is ground, so nfr3's symbolic value terms (evalx,
% term_variables, grounds) are gone. Same <-- dialect, same
% compile-at-preprocess design.
:- op(1100, xfx, <--).
:- op(900,  fy,  no).
:- dynamic (<--)/2, seen/2, greedy/0.   % greedy: commit or-choices
:- discontiguous (<--)/2.

permute(Xs,Ys) :- random_permutation(Xs,Ys).

% ---- beliefs: the database, undone on backtrack --------------------------
learn(K,V) :- assertz(seen(K,V)).
learn(K,V) :- retract(seen(K,V)), fail.

% maybe(K,V,Vals): recall K, else assume a value (a demand is
% assumed as given; a free V draws from Vals).
maybe(K,V,_)    :- seen(K,W), !, V = W.
maybe(K,V,Vals) :- ( var(V) -> draw(V,Vals) ; true ),
                   learn(K,V).

draw(V,Vals) :- greedy, !, random_member(V,Vals).  % ISAMP: one guess,
draw(V,Vals) :- permute(Vals,Ps), member(V,Ps).    % no local retry

% ---- hard side -----------------------------------------------------------
% falsity is assumed, never derived: `no` skips the node's clauses.
lits([],_).
lits([L|Ls],P) :- lit(L,P), lits(Ls,P).
lit(no(K),_) :- !, maybe(K,-2,[]).
lit(K,    P) :- ev(K,2,P).

walk(Bs,P) :- greedy, !, random_member(B,Bs), permute(B,Ls), lits(Ls,P).
walk(Bs,P) :- permute(Bs,Rs), member(B,Rs), permute(B,Ls), lits(Ls,P).

% ---- soft side: contributions are plain numbers --------------------------
contrib(no(K),   -2,_) :- !, maybe(K,-2,[]).
contrib(makes(X), V,P) :- !, ev(X,V,P).
contrib(breaks(X),V,P) :- !, ev(X,W,P), V is -W.
contrib(helps(X), V,P) :- !, ev(X,W,P), V is sign(W)*min(1,abs(W)).
contrib(hurts(X), V,P) :- !, ev(X,W,P), V is -sign(W)*min(1,abs(W)).
contrib(and(Xs),  V,P) :- !, evs(Xs,P,Ws), min_list(Ws,V).
contrib(or(Xs),   V,P) :- !, evs(Xs,P,Ws), max_list(Ws,V).

contribs([],_,[]).
contribs([E|Es],P,[W|Ws]) :- contrib(E,W,P), contribs(Es,P,Ws).

evs([],_,[]).
evs([X|Xs],P,[W|Ws]) :- ev(X,W,P), evs(Xs,P,Ws).

% combine: strongest support + strongest objection; a loop's
% early guess (already in seen) must equal the computed label.
combine(K,Ws,V) :- max_list([0|Ws],Hi), min_list([0|Ws],Lo),
                   \+ (Hi =:= 2, Lo =:= -2),      % sat meets denied
                   V is Hi + Lo,
                   ( seen(K,W) -> W =:= V ; learn(K,V) ).

% ---- compiler ------------------------------------------------------------
% head(K,H,V,P): K's compiled predicate takes a value and the
% downward path of heads now being computed.
head(K,H,V,P) :- K =.. Ws, append(Ws,[V,P],Zs), H =.. Zs.

ev(K,V,P) :- head(K,H,V,P), call(H).

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
  head(K,H,V,P),
  assertz((H :- seen(K,W), !, V = W)),           % memo: O(1) recall
  assertz((H :- memberchk(K,P), !,               % loop: guess now, my
                maybe(K,V,[2,1,0,-1,-2]))),      % combine verifies
  findall(B, (K <-- B), Bs),
  include(hard, Bs, Hs),
  ( Hs = [_|_] -> compile1or(K,Hs) ; compile1and(K,Bs) ).

compile1or(K,Bs) :-                          % any all-hard body: rules win
  head(K,H,2,P),                             % (only ever prove 2; edges on
  assertz((H :- learn(K,2),                  % a mixed head are dead). Head
                walk(Bs,[K|P]))).            % first, so loops close true.

compile1and(K,Bs) :-                         % edges; a bound-V demand is
  append(Bs,Es0), maplist(wrap,Es0,Es),      % assumed, never derived
  head(K,H,V,P),
  assertz((H :- ( var(V)
                -> permute(Es,Rs), contribs(Rs,[K|P],Ws), combine(K,Ws,V)
                ;  learn(K,V) ))).

stub(K) :- head(K,H,V,_), assertz((H :- maybe(K,V,[2,-2]))).

heads(Ks)  :- findall(K, (K <-- _), Ks0), sort(Ks0,Ks).
leaves(Ls) :- heads(Ks),
              findall(X, ((_ <-- B), member(E,B), ref(E,X)), Xs0),
              sort(Xs0,Xs), subtract(Xs,Ks,Ls).

preprocess :- heads(Ks),  maplist(compile1, Ks),
              leaves(Ls), maplist(stub, Ls).

% ---- top ----------------------------------------------------------------
reset :- retractall(seen(_,_)).

abduce(G,As)   :- reset, lit(G,[]), picks(As).
soften(G,V,As) :- reset, ev(G,V,[]), picks(As).

picks(As) :- findall(K-V, seen(K,V), A), msort(A,Ps),
             findall(X, (member(K-V,Ps), leaf(K,V,X)), As).
leaf(K,_,_)      :- (K <-- _), !, fail.      % derived: hide, show leaves
leaf(K, 2, K)    :- !.
leaf(K,-2, no K) :- !.
leaf(K, V, lab(K,V)).
