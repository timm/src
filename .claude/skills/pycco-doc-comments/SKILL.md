---
name: pycco-doc-comments
description: Write per-function doc comments that land in pycco's left docs column - signature line, prose, and per-section intro notes. Use when adding or auditing comments in any lua/py/lisp file under a dir with an INSTALL.md, or when a docs page reads as bare code with an empty left column.
---

# Doc comments that reach the pycco docs column

Worked example: every file in ezr-lua/ (Aug 2026). Pipeline
and its bugs: the repo-root memory note on the two doc
pipelines; shape rules: etc/style.md.

## The one rule pycco cares about

A comment at **column 0** becomes docs-column prose. A
comment **trailing a code line** stays in the code column.
So a function note written as `function f(x) -- does a
thing` is invisible in the docs; the same note on its own
line above `function f(x)` is a paragraph on the left.

House shape, per definition:

```lua
-- *`TBL:disty(row:row) -> num`*␠␠
-- Gap to heaven; 0 = best. Rows born "?" get labelled on
-- demand, right here.
function TBL.disty(i,row)
```

renders as one paragraph: monospace signature, hard line
break, prose. **The two trailing spaces are required.** They
are Python-Markdown's hard break. The `\` form does NOT work
(tested). A blank `--` line instead gives two paragraphs,
which spreads the pair too far apart.

Per **section** (`--## name ----`), add 2-6 lines of prose
directly under the marker: what this group is for and why it
exists, not what each function does. It renders under the
`<h2>`, in its own docs cell.

## Signature vocabulary

Lua has no types; these are a reading aid, so keep the set
tiny and never invent a word for one use.

    list  dict  row  col  str  num  int  bool  fun  any
    NUM SYM COLS TBL NODE TREE THE      class names
    ?:    optional arg          x?:int
    ->    returns               , separates multiple returns
    {a:list, b:dict}            a returned record

- `list` = table used as an array, `dict` = used as a map.
  Say which; `tab` tells the reader nothing.
- Methods take their **call-site** form: `TBL:disty(row:row)`,
  not `TBL.disty(i,row)`. Drop the `i`.
- **Names after the wide gap are LOCALS, not arguments** —
  they never appear in a signature. `NUM.add(i,v,inc,    d)`
  is `NUM:add(v:num, inc?:int) -> num`. Say this once in the
  first section note of each file; it is the trap newcomers
  hit.
- A returned record beats a bare `dict` when callers index
  known fields: `ranks(..) -> {winners:list, ranks:dict}`.
- Demos are not functions: give them their invocation
  instead, `` *`lua ezr-eg.lua --tree`* ``.

## Keep inline comments that annotate ONE line

Move the function's *description* up; leave line-scoped notes
where they are (`-- strip any BOM`, `-- budget spent`,
`-- best leaf`). Losing those to the left column disconnects
them from the line they explain.

## Styling the signature (already wired)

`<em><code>` is a selector nothing else in the docs column
produces. The repo Makefile's `timm extras` block sets
`.docs em code` to monospace with `font-style: normal` (kills
fake-oblique). pycco **rewrites pycco.css every run**, so the
block's `grep -q 'timm extras'` guard always fails and the
extras always re-append — edit the Makefile and it just
works, no stale-block trap.

## Gates (run all; comments must change nothing)

    # BEFORE editing, freeze the output
    for f in *-eg.lua ...; do lua $f --all > /tmp/base-$f; done
    # AFTER: byte-identical, under BOTH interpreters
    for I in lua luajit; do $I $f --all | diff - /tmp/base-$f; done
    awk 'length > 65' *.lua        # -> nothing new
    make doc && python3 etc/doc.py # both clean
    grep -c '<em><code>' docs/<dir>/*.html   # sigs landed

## Common mistakes

| Mistake | Fix |
|---|---|
| Editing `docs/*.html` directly | Generated. Edit the source, `make doc` |
| Trailing spaces stripped on save | Hard break dies, hints collapse into prose. Check `grep -c '  $'` after |
| Rewriting a whole file to move comments | Fine, but diff the frozen `--all` output; a dropped assert is silent otherwise |
| Losing a form feed | `\f` prefixes some `--## ` markers (a2ps page breaks). `grep -n $'\f'` before and after |
| A re-wrap that pushes prose past 65 | Re-run the awk gate after EVERY prose edit, not once at the end |
| Saying "italic"/"monospace" in the prose | Describes the CSS, which changes. Say "the signature above each function" |
