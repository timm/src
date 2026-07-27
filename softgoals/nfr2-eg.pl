% nfr-eg.pl : example models for nfr.pl.
:- ['nfr2.pl'].
:- initialization(main, main).

% ---- horn: loops and choice ---------------------------------------------
happy   <- [rich].
happy   <- [loved, not lonely].
rich    <- [works, lucky].
loved   <- [friends].
friends <- [happy].          % loop: happy -> loved -> friends -> happy

% ---- horn: inconsistency ------------------------------------------------
g <- [p, q].
p <- [x].
q <- [not x].                % needs x and not x

% ---- softgoals ----------------------------------------------------------
performance <~ [help(indexing), hurt(logging)].
security    <~ [make(encryption), hurt(indexing)].
usability   <~ [break(encryption), help(gui)].
good        <~ [and([performance, security, usability])].
trust       <~ [help(good), make(trust)].          % self loop

main :- findall(A, abduce(happy,A), H), sort(H,HS), format("happy ~w~n",[HS]),
        findall(A, abduce(g,A), G),                 format("g     ~w~n",[G]),
        findall(V-A, soften(good,V,A), L), sort(L,S), length(S,N),
        last(S, Best), format("good  ~w worlds, best ~w~n",[N,Best]),
        findall(V, soften(trust,V,_), T), sort(T,TS), format("trust ~w~n",[TS]).
