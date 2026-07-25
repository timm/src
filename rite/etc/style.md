# style.md -- how a Menzies PAPER reads (rite edition)

Synthesis of two sources. (1) The proposal-voice style.md
(SLES/DRR/BINGO/EZR, amended July 2026) -- its rules carry
over unless overridden here. (2) Habits observed in the
published/preprint papers now in pdf/ and pdf/mine/:
Agrawal ICSE'18, Chakraborty FSE'21, Ganguly's optimizer
tournament (2607.11705), SNAP2 (2607.02583), the fuzzing
IST preprint (2512.18102). Target: text that passes as a
first-draft Menzies paper, not LLM output.

The content now lives in seven skills, one per prompt
division, under ../.claude/skills/ (loaded on demand when
a session runs from the rite root). Each skill = short
quotable form first, moved-whole detail after. HOWTO.md
maps the 14 loop steps to these skills.

| skill     | sections it holds                          |
|-----------|--------------------------------------------|
| choose    | Newell's springboard; Wheeler counterweight |
| search    | recent-by-velocity; knee pipeline pointers  |
| encode    | THE ABSTRACT CARRIES THE PAPER; thr rules   |
| structure | paper skeleton; section order and duties;   |
|           | Widom's five; imports from Widom            |
| prose     | opening moves; argument habits; sentence    |
|           | mechanics; LaTeX conventions; banned LLM    |
|           | tells                                       |
| critics   | Shaw's rules; Laurie's Laws; assemble your  |
|           | critics                                     |
| ship      | quick self-test before shipping             |

House rule for every skill file: edits are audit-and-add,
smallest span that fixes the problem; move sections whole,
never retype them.
