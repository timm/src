% gen18.pl : keys-from-sampling pipeline over one goal model.
% Generate n1 worlds (hard goals gated: [h,h=t,...,[and|softs]]),
% take the best by d2h, filter its controllable labels to the
% non-unanimous, Zeller-ddmin those to a minimal seed, assess with
% reps more replays. All constants named just below.
% Run: swipl -g "run('models/CSServices.pl')" -g halt gen18.pl
% Out: dataset,mu,sd,best,muSeed,sdSeed,n_filt,|seed|,#tests,%seed,gen_ms,ddmin_ms,assess_ms
:- ['nfr5.pl'].

% The rig's constants, all of them:
n1(1000).    % worlds sampled: sets the target (best-of-n1) and the
             % unanimity counts; 256 usually finds the same optima
n2(30).      % replays per quality estimate, in ddmin tests and the
             % final assessment alike; below ~30 ddmin misjudges
             % (winner's-curse seeds, bloat) -- measured at 10
eps(0.05).   % ablation damage threshold: a subset survives only if
             % its mean d2h stays within eps of the best world.
             % Part noise floor (a 30-replay mean wobbles ~0.02),
             % part price: ddmin spends whatever noise leaves, so
             % muSeed sits near best+eps by construction
seed(1).     % RNG pin: the table is reproducible, and draw-fragile
z0(2).       % zeller: start (and minimum) granularity -- how many
             % chunks ddmin first splits a candidate set into
zup(2).      % zeller: granularity multiplier when neither a chunk
             % nor a complement passes (search goes finer)
zdn(1).      % zeller: granularity step-down after a complement cut
             % (set shrank, so fewer chunks suffice)

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
  n2(R),
  findall(D, (between(1,R,_), isamp(Gs,[replay=on|Seed],W),
              score(P,W,S), d2h(MM,S,D)), Ds),
  length(Ds,N), N > 0, sumlist(Ds,Su), Mu is Su/N,
  Mu =< Tol.

ddmin(_, C, _, C) :- length(C,1), !.
ddmin(T, C, N, Min) :-
  chunks(C, N, Cs),
  ( member(Ci, Cs), call(T, Ci)                   % IF   a chunk passes alone
    -> z0(Z), ddmin(T, Ci, Z, Min)                 % THEN recurse into it
  ; member(Cj, Cs), subtract(C, Cj, Rest),         % ELIF dropping a chunk
    call(T, Rest)                                  %      still passes
    -> z0(Z), zdn(Dn), N1 is max(N-Dn,Z),          % THEN recurse without it
       ddmin(T, Rest, N1, Min)
  ; length(C, LC), N < LC                          % ELIF chunks not yet singletons
    -> zup(Up), N2 is min(LC, Up*N),               % THEN split finer
       ddmin(T, C, N2, Min)
  ; Min = C ).                                     % ELSE 1-minimal: done

% the query: derive-and-demand every hard goal, then all softs
query(Gs) :-
  ( (goals(hard) <-- Hs) -> true ; Hs = [] ),
  ( (goals(soft) <-- [or|Ss]) -> true ; Ss = [] ),
  foldl([H,A0,A1]>>(A1=[H,H=t|A0]), Hs, [[and|Ss]], Gs).

% n1 worlds, each scored and d2h-normalized over the batch
generate(Gs, P, MM, DWs) :-
  n1(N),
  findall(W-S, (between(1,N,_), isamp(Gs,[],W), score(P,W,S)), WSs),
  mm0(M0), foldl([_-S,A,B]>>mmadd(S,A,B), WSs, M0, MM),
  findall(D-W, (member(W-S,WSs), d2h(MM,S,D)), DWs).

musd(Ds, Mu, Sd) :-
  length(Ds,N), sumlist(Ds,Su), Mu is Su/N,
  foldl([D,A,B]>>(B is A+(D-Mu)**2), Ds, 0, SS), Sd is sqrt(SS/N).

% best world's controllables, minus labels every world shares
candidates(DWs, WBest, Cands) :-
  findall(X=V, (member(X=V,WBest), controllable(X)), Full),
  findall(W, member(_-W,DWs), Ws),
  findall(PV, ( member(PV,Full),
                \+ forall(member(W,Ws), memberchk(PV,W)) ),
          Cands).

minimize(Gs, P, MM, DBest, Cands, Seed, NTests) :-
  eps(E), Tol is DBest + E,
  nb_setval(tests, 0),
  z0(Z), ddmin(passes(Gs,P,MM,Tol), Cands, Z, Seed),
  nb_getval(tests, NTests).

% n2 fresh replays under the minimized seed
assess(Gs, P, MM, Seed, Mu, Sd) :-
  n2(N),
  findall(D, (between(1,N,_), isamp(Gs,[replay=on|Seed],W),
              score(P,W,S), d2h(MM,S,D)), Ds),
  musd(Ds, Mu, Sd).

shortname(File, Base) :-
  file_base_name(File,B0), atom_concat(B1,'.pl',B0),
  ( atom_concat('CS',Base,B1) -> true ; Base = B1 ).

run(File) :-
  consult(File), seed(RS), set_random(seed(RS)),
  query(Gs), prep(P),
  statistics(walltime,[T0,_]),
  generate(Gs, P, MM, DWs),
  statistics(walltime,[T1,_]),
  findall(D, member(D-_,DWs), Ds), musd(Ds, Mu0, Sd0),
  msort(DWs, [DBest-WBest|_]),
  candidates(DWs, WBest, Cands), length(Cands, NC),
  statistics(walltime,[T2,_]),
  minimize(Gs, P, MM, DBest, Cands, Seed, NTests),
  statistics(walltime,[T3,_]),
  assess(Gs, P, MM, Seed, MuS, SdS),
  statistics(walltime,[T4,_]),
  length(Seed, NS), mentions(Xs), length(Xs, NM), Pct is 100*NS/NM,
  shortname(File, Base),
  Gen is T1-T0, Dd is T3-T2, As is T4-T3,
  format("~w,~4f,~4f,~4f,~4f,~4f,~w,~w,~w,~1f,~w,~w,~w~n",
         [Base,Mu0,Sd0,DBest,MuS,SdS,NC,NS,NTests,Pct,Gen,Dd,As]).
