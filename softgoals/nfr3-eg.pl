% nfr3-eg.pl : example models for nfr3.pl (same graphs as nfr2-eg.pl,
% all written with one arrow; hard vs soft read off the body shapes).
:- ['nfr3.pl'].
:- initialization(main, main).

% ---- horn: loops and choice ---------------------------------------------
happy   <-- [rich].
happy   <-- [loved, no lonely].
rich    <-- [works, lucky].
loved   <-- [friends].
friends <-- [happy].         % loop: happy -> loved -> friends -> happy

% ---- horn: inconsistency ------------------------------------------------
g <-- [p, q].
p <-- [x].
q <-- [no x].                % needs x and not x

% ---- softgoals ----------------------------------------------------------
performance <-- [helps(indexing), hurts(logging)].
security    <-- [makes(encryption), hurts(indexing)].
usability   <-- [breaks(encryption), helps(gui)].
good        <-- [and([performance, security, usability])].
trust       <-- [helps(good), makes(trust)].       % self loop

% ---- goals --------------------------------------------------------------
goals(hard) <-- [happy].                     % conjunction: must ALL solve
                                             % (adding g here kills every world)
goals(soft) <-- [or([performance, security, usability])].

main :- preprocess,
        findall(A, abduce(happy,A), H), sort(H,HS), format("happy ~w~n",[HS]),
        findall(A, abduce(g,A), G),                 format("g     ~w~n",[G]),
        findall(A, abduce(goals(hard),A), GH),      format("hard  ~w~n",[GH]),
        findall(V-A, soften(good,V,A), L), sort(L,S), length(S,N),
        last(S, Best), format("good  ~w worlds, best ~w~n",[N,Best]),
        findall(V, soften(trust,V,_), T), sort(T,TS), format("trust ~w~n",[TS]),
        findall(V-A, soften(goals(soft),V,A), L2), sort(L2,S2),
        last(S2, B2), format("soft  best ~w~n",[B2]).
