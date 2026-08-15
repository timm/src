% nfr5-eg.pl : Kids Help Phone anonymity story (models/CSServices.pl,
% names abbreviated). Choosing anonymity picks the anon tech and
% refuses the named tech; choosing feedback leaves tech to chance.
:- ['nfr5.pl'].
:- initialization(main, main).

top <-- [ or([anonymity, feedback]), anonTech ].

anonymity <-- [ makes(anonTech), breaks(namedTech),
                helps(phone),    hurts(video) ].

anonTech <-- [bboard].
anonTech <-- [voice].

main :- forall(between(1,5,_),
               (isamp(top,[],W), format("~w~n",[W]))),
        isamp(top,[feedback=t],W2), format("seeded ~w~n",[W2]).
