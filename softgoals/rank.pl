% rank.pl : rank decision settings by mean distance-to-heaven of
% the worlds containing them (one batch, no iteration), then TEST:
% fix the top-k as priors, sample 20 worlds per k, report means.
% The k where the curve plateaus = decisions that need deliberation.
% usage: swipl rank.pl models/CSServices.pl
:- [nfr3].
:- assertz(greedy).
:- initialization(main, main).

hardgoals(Hs) :- (goals(hard) <-- Hs), !.
hardgoals([]).
softgoals(Ss) :- (goals(soft) <-- [or(Ss)]), !.
softgoals([]).

hards([])     --> [].
hards([H|Hs]) --> lit(H), !, hards(Hs).

softs([],K,K)      --> [].
softs([S|Ss],K0,K) --> ( call(S,V) -> { number(V), V >= 2 -> K1 is K0+1
                                      ; K1 = K0 }
                       ; { K1 = K0 } ),
                       softs(Ss,K1,K).

world(Pr,w(B,K,D,A)) :-
    hardgoals(Hs), softgoals(Ss),
    between(1,100,_),
    permute(Hs,Rs), hards(Rs,Pr,A1), !,
    permute(Ss,Ps), softs(Ps,0,K,A1,A),
    leaves(Ls),
    aggregate_all(count,(member(L,Ls),memberchk(L-2,A)),D),
    dist(K,D,B).

dist(K,D,B) :- softgoals(Ss), length(Ss,NS0), NS is max(1,NS0),
               leaves(Ls),    length(Ls,NL0), NL is max(1,NL0),
               S is K/NS, C is D/NL,
               B is sqrt((1-S)^2 + C^2)/sqrt(2).

% mean d of the worlds where setting L-V holds; support >= 10
rank(Ws,Os) :-
    leaves(Ls),
    findall(M-(L-V),
            ( member(L,Ls), member(V,[2,-2]),
              findall(B,(member(w(B,_,_,A),Ws),memberchk(L-V,A)),Bs),
              length(Bs,N), N >= 10,
              sum_list(Bs,S), M is S/N ),
            Rs),
    msort(Rs,Ss), findall(C,member(_-C,Ss),Os).

test(Os,K,Row) :-
    pfx(Os,K,[],Pr), length(Pr,Got), Got =:= K,
    findall(B-(S-D), (between(1,20,_), world(Pr,w(B,S,D,_))), Ws),
    length(Ws,N), N > 0,
    findall(B,member(B-_,Ws),Bs), avg(Bs,MB),
    findall(S,member(_-(S-_),Ws),Ss2), avg(Ss2,MS),
    findall(D,member(_-(_-D),Ws),Ds), avg(Ds,MD),
    Row = row(K,N,MB,MS,MD).

pfx(_,0,Acc,Pr) :- !, reverse(Acc,Pr).
pfx([L-V|Os],K,Acc,Pr) :-
    ( memberchk(L-_,Acc) -> pfx(Os,K,Acc,Pr)
    ; K1 is K-1, pfx(Os,K1,[L-V|Acc],Pr) ).
pfx([],_,Acc,Pr) :- reverse(Acc,Pr).

avg(L,M) :- sum_list(L,S), length(L,N), M is S/N.

main :- preprocess,
        set_random(seed(1)), statistics(cputime,T0),
        findall(W,(between(1,200,_),world([],W)),Ws),
        rank(Ws,Os),
        leaves(Ls), length(Ls,NL0), NL is max(1,NL0),
        softgoals(Sg), length(Sg,NS0), NS is max(1,NS0),
        findall(R, (member(K,[0,1,2,3,4,6,8,12,16,24,32,48,64]),
                    K =< NL, test(Os,K,R)), Rows),
        statistics(cputime,T1), T is T1-T0,
        forall(member(row(K,N,MB,MS,MD),Rows),
               ( KP is 100*K/NL, SP is 100*MS/NS, CP is 100*MD/NL,
                 format("k=~w (~1f% dec) worlds ~w | mean d ~3f | soft ~1f% | cost ~1f%~n",
                        [K,KP,N,MB,SP,CP]) )),
        findall(MB-row(K,N,MB,MS,MD),member(row(K,N,MB,MS,MD),Rows),BK),
        msort(BK,[Bst-row(Kst,_,_,MSb,MDb)|_]), KPb is 100*Kst/NL,
        SPb is 100*MSb/NS, CPb is 100*MDb/NL,
        format("PLATEAU: k*=~w (~1f% of decisions) mean d ~3f | soft ~1f% | cost ~1f% | ~1fs~n",
               [Kst,KPb,Bst,SPb,CPb,T]).
