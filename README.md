# timm/src

One repo, one flat dir per idea: many page-sized source
files plus one `-eg` tutorial/test twin each, fetched by
`curl <dir>/INSTALL.md | sh`. Data lives in
[timm/moot](https://github.com/timm/moot) (`$MOOT`, default
`~/gits/moot`). Design rationale: [etc/style.md](etc/style.md).

| dir | what | docs | run its examples |
|-----|------|------|------------------|
| [ezr2](ezr2/) | explainable multi-objective optimization (Python) | [pages](https://timm.github.io/src/ezr2/docs/ezr2.html) | `python3 ezr2-eg.py all` |
| [tiny-xai](tiny-xai/) | same ideas, Common Lisp, tiny-function style | [pages](https://timm.github.io/src/tiny-xai/docs/tiny-xai.html) | `sbcl --script tiny-xai-eg.lisp --all` |
| [luamine](luamine/) | AI primitives + apps (Lua) | [pages](https://timm.github.io/src/luamine/) | `lua luamine-eg.lua --all` |

Site: [timm.github.io/src](https://timm.github.io/src/).

    git clone https://github.com/timm/moot ~/gits/moot   # data, once
    make eg                                              # run everything
