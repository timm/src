# timm/src

One repo, one flat dir per idea: one sectioned library
file plus one `-eg` tutorial/test file (and demos), fetched
by `curl <dir>/INSTALL.md | sh`. Data lives in
[timm/moot](https://github.com/timm/moot) (`$MOOT`, default
`~/gits/moot`). Design rationale: [etc/style.md](etc/style.md).

The `ezr-*` dirs are one idea -- explainable
multi-objective optimization (columns, distance, cheap
labels, trees) -- each written as its own app in its own
language.

| dir | what | docs | run its examples |
|-----|------|------|------------------|
| [ezr-py](ezr-py/) | explainable multi-objective optimization (Python) | [pages](https://timm.github.io/src/ezr-py/docs/ezr2.html) | `python3 ezr2-eg.py all` |
| [ezr-lua](ezr-lua/) | same ideas, Lua, tiny-ly | [pages](https://timm.github.io/src/ezr-lua/docs/xai.html) | `lua xai-eg.lua --all` |
| [ezr-lisp](ezr-lisp/) | same ideas, Common Lisp, tiny-function style | [pages](https://timm.github.io/src/ezr-lisp/docs/tiny-xai.html) | `sbcl --script tiny-xai-eg.lisp --all` |

Retired to [attic/](attic/): [luamine](attic/luamine/),
the frozen ten-lecture Lua REPL course (still
replay-verified: `lua luamine-eg.lua --all; lua tutchk.lua`).

Site: [timm.github.io/src](https://timm.github.io/src/).

    git clone https://github.com/timm/moot ~/gits/moot   # data, once
    make eg                                              # run everything
