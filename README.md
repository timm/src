# timm/src

One repo, one flat dir per idea; each idea is one wget-able
library file plus an `-eg` examples/tests file. Data lives in
[timm/moot](https://github.com/timm/moot) (`$MOOT`, default
`~/gits/moot`). Design rationale: [etc/style.md](etc/style.md).

| dir | what | run its examples |
|-----|------|------------------|
| [ezr2](ezr2/) | explainable multi-objective optimization (Python) | `python3 ezr2-eg.py all` |
| [tiny-xai](tiny-xai/) | same ideas, Common Lisp, tiny-function style | `sbcl --script tiny-xai-eg.lisp --all` |
| [luamine](luamine/) | AI primitives + apps (Lua) | `lua luamine-eg.lua --all` |

    git clone https://github.com/timm/moot ~/gits/moot   # data, once
    make eg                                              # run everything
