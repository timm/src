---
name: tut-weave
description: Structure and build of the split ezr-lua tutorial — tut/ part files woven into tut.md by make, with answer-release gating. Use before editing tut.md (it is GENERATED) or adding lectures/questions/answers.
---

# tut/ weave (ezr-lua)

`ezr-lua/tut.md` is **generated**: `make tut.md` concatenates, in
order: `tut/front.md, l0.md..l10.md, lua101.md, [answers], 
glossary.md, refs.md`. NEVER hand-edit tut.md; edit the part file
and re-weave. The zip ships only the woven tut.md, not tut/.

- `make tut.md RELEASED=3` splices `tut/ans/a1..a3.md` (an "Exam
  answers" section) before the glossary. Unset RELEASED = no
  answers published. Policy: answers ship one week behind questions.
- Each `lN.md`: anchor + title, then `**Words to watch for:**`
  (links into glossary), body with REPL traces, exercises, then
  `## Exam questions` last (see tut-exam-questions skill).
- Trace verification is UNCHANGED by the split: `etc/tut/lN.in` +
  `etc/tut/repl.lua` (`EZR=$PWD lua etc/tut/repl.lua etc/tut/lN.in
  <start>`); appendix events 1000+ in `etc/tut/appendix.in`
  (47 events as of 2026-08-10). Check lua vs luajit traces diff
  empty.
- The old "Revision guide (gated questions)" / "Worked answers"
  sections were dissolved 2026-08-10: questions migrated into their
  lectures by gate number (L1 gets gate<=16, L2 17-36, L3 37-53,
  L4 54-69, L5 70-84, L6 85-94, L7 95-108, L8 109-124, L9 125-142,
  L10 143+), answers seeded `tut/ans/aN.md`. Do not resurrect
  `#quiz`/`#answers` anchors; `#answers` exists only in RELEASED
  weaves.
- After any weave: `make demo` (failures: 0) and one lecture
  replay as smoke.
