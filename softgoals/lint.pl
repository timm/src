% lint.pl : swipl -g lint model.pl lint.pl -- shout about silent breakage
norm(A,N) :- downcase_atom(A,D), atomic_list_concat(Ws,' ',D),
             exclude(==(''),Ws,Ws1), atomic_list_concat(Ws1,' ',N).
lint :- forall((edge(A,_,_), \+node(A,_)),
               format("orphan edge source: ~q~n",[A])),
        forall((edge(_,B,_), \+node(B,_)),
               format("orphan edge target: ~q~n",[B])),
        forall((node(A,_), node(B,_), A @< B, norm(A,N), norm(B,N)),
               format("near-duplicate names: ~q / ~q~n",[A,B])),
        forall((topgoal(G), \+edge(_,G,_)),
               format("unsupported top goal: ~q~n",[G])),
        forall((node(N,_), \+edge(N,_,_), \+edge(_,N,_)),
               format("isolated node: ~q~n",[N])),
        halt.
