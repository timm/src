% expand.pl : leaf/1 and topgoal/1 are derived, not declared. A leaf
% is a known node with no definition (no <- rule, no <~ edge); a
% topgoal is a node of type goal (a hard goal, often mid-graph -- so
% not derivable from structure, only from the type). Both checked
% against the hand-declared sets of all seven models/: exact match.
%
% node/2 stays declared in models: it is the one non-derivable fact.
% Types do not follow the operator split (models refine softgoals
% with <- and cite tasks inside <~ contributions), and some nodes
% appear in no clause at all.
% Models write one compact types(Type, [Name,...]) fact per type;
% term_expansion unfolds it into node/2 facts at load time, so the
% database still gets first-arg-indexed node(X,T).
:- op(900, fy, not).
:- op(1100, xfx, <-).
:- op(1100, xfx, <~).
:- dynamic (<-)/2, (<~)/2, node/2.

term_expansion(types(T,Xs), Ns) :- findall(node(X,T), member(X,Xs), Ns).

leaf(X)    :- node(X, _), \+ (X <- _), \+ (X <~ _).
topgoal(X) :- node(X, goal).
