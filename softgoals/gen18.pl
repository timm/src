% gen18.pl : keys-from-sampling pipeline over one goal model.
% Generate N1=1000 worlds (hard goals gated: [h,h=t,...,and(softs)]),
% take the best by d2h, Zeller-ddmin its controllable labels down to
% a minimal seed (test = 30 replays with replay=on within
% best+0.05), then assess the seed with N2=100 replays.
% Run: swipl -g "run('models/CSServices.pl')" -g halt gen18.pl
% Out: dataset,mu1000,sd1000,best,mu100,sd100,n_full,|seed|,#tests,%seed,ddmin_s
:- ['nfr5.pl'].

% These two predicates define ddmin's candidate pool, and the pool
% decides whether the whole pipeline works: seeds must hold only
% labels a stakeholder could actually SET. Seeding a consequence
% (a quality, a derived head) fakes benefit for free, blocks the
% subtree behind it from ever running, and taught the sampler
% nothing -- measured, such seeds scored WORSE than random.
% The dialect has ONE or-form (a body [or|Alts]), so one clause:
choicy(X) :- (H <-- [or|Alts]),  % X names an alternative: its label is
             H \= goals(_),      % the world's only trace of which branch
             member(X,Alts), !.  % won -- pin it, replay the choice.
                                 % goals(_) excluded: that or is the
                                 % query's quality list, and qualities
                                 % are outcomes, not decisions

% What can a stakeholder set? A leaf (nothing derives it, so its
% label can only come from fiat or assumption -- these are the
% assumptions the footprint score charges for) or an or-branch
% atom. Everything else is derived by necessity: asserting it
% restates what the model already forces, and every redundant
% candidate costs ddmin a round of 30-replay tests.
controllable(X) :- ( \+ head(X) ; choicy(X) ), !.

chunks([], _, []) :- !.
chunks(L, N, [C|Cs]) :-
  length(L, Len), Sz is max(1, (Len + N - 1)//N),
  length(C, Sz), append(C, Rest, L), !,
  N1 is max(1, N-1), chunks(Rest, N1, Cs).
chunks(L, _, [L]).

passes(Gs,P,MM,Tol,Seed) :-
  nb_getval(tests,T), T1 is T+1, nb_setval(tests,T1),
  findall(D, (between(1,30,_), isamp(Gs,[replay=on|Seed],W),
              score(P,W,S), d2h(MM,S,D)), Ds),
  length(Ds,N), N > 0, sumlist(Ds,Su), Mu is Su/N,
  Mu =< Tol.

ddmin(_, C, _, C) :- length(C,1), !.
ddmin(T, C, N, Min) :-
  chunks(C, N, Cs),
  ( member(Ci, Cs), call(T, Ci)                    % IF   a chunk passes alone
    -> ddmin(T, Ci, 2, Min)                        % THEN recurse into it
  ; member(Cj, Cs), subtract(C, Cj, Rest),         % ELIF dropping a chunk
    call(T, Rest)                                  %      still passes
    -> N1 is max(N-1,2), ddmin(T, Rest, N1, Min)   % THEN recurse without it
  ; length(C, LC), N < LC                          % ELIF chunks not yet singletons
    -> N2 is min(LC, 2*N), ddmin(T, C, N2, Min)    % THEN split finer
  ; Min = C ).                                     % ELSE 1-minimal: done

run(File) :-
  consult(File),
  set_random(seed(1)),
  ( (goals(hard) <-- Hs) -> true ; Hs = [] ),
  ( (goals(soft) <-- [or|Ss]) -> true ; Ss = [] ),
  foldl([H,A0,A1]>>(A1=[H,H=t|A0]), Hs, [[and|Ss]], Gs),
  prep(P),
  statistics(walltime,[TG0,_]),
  findall(W-S, (between(1,1000,_), isamp(Gs,[],W), score(P,W,S)), WSs),
  mm0(M0), foldl([_-S,A,B]>>mmadd(S,A,B), WSs, M0, MM),
  findall(D-W, (member(W-S,WSs), d2h(MM,S,D)), DWs),
  msort(DWs, [DBest-WBest|_]),
  length(DWs,N1), aggregate_all(sum(DX), member(DX-_,DWs), SumD),
  Mu0 is SumD/N1,
  foldl([DY-_,A0,B0]>>(B0 is A0+(DY-Mu0)**2), DWs, 0, SS0),
  Sd0 is sqrt(SS0/N1),
  statistics(walltime,[TG1,_]),
  findall(X=V, (member(X=V,WBest), controllable(X)), Full0),
  findall(W0, member(_-W0,DWs), AllWs),
  findall(PV, ( member(PV,Full0),
                \+ forall(member(W1,AllWs), memberchk(PV,W1)) ),
          Full),
  length(Full, NF),
  Tol is DBest + 0.05,
  nb_setval(tests, 0),
  statistics(walltime,[T0,_]),
  ddmin(passes(Gs,P,MM,Tol), Full, 2, Seed),
  statistics(walltime,[T1,_]),
  length(Seed, NS), nb_getval(tests, NT),
  findall(D2, (between(1,100,_), isamp(Gs,[replay=on|Seed],W3),
               score(P,W3,S3), d2h(MM,S3,D2)), Ds),
  statistics(walltime,[TA1,_]),
  length(Ds,NR), sumlist(Ds,Su), MuR is Su/NR,
  foldl([D3,A,B]>>(B is A+(D3-MuR)**2), Ds, 0, SS), SdR is sqrt(SS/NR),
  DD is (T1-T0)/1000,
  mentions(Xs), length(Xs,NM), Pct is 100*NS/NM,
  file_base_name(File,B0a), atom_concat(B0b,'.pl',B0a),
  ( atom_concat('CS',Base,B0b) -> true ; Base = B0b ),
  GenMs is TG1-TG0, DdMs is T1-T0, AsMs is TA1-T1,
  format("~w,~4f,~4f,~4f,~4f,~4f,~w,~w,~w,~1f,~w,~w,~w~n",
         [Base,Mu0,Sd0,DBest,MuR,SdR,NF,NS,NT,Pct,GenMs,DdMs,AsMs]).
