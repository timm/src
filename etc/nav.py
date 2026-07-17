#!/usr/bin/env python3
"""
nav.py docs/<proj>/NAME.html: inject badges and
<prev | next> links into a pycco page, before its first
<h1>.

One page per source file; order and code/tests grouping
come from the .order manifest beside the page (written by
make doc from `sh INSTALL.md list`). The <h1> links to the
source file on github. Code pages right-align their prose
(dense margin notes); tests/tutorial pages read left.
"""
import os, re, sys

REPO = "https://github.com/timm/src"
B    = "https://img.shields.io/badge"
PROJ = os.path.basename(os.getcwd())
LANG = {".lisp": ("common%20lisp", "sbcl%20|%20clisp"),
        ".py":   ("python", "python3"),
        ".lua":  ("lua", "lua5.4")}

page  = sys.argv[1]                      # ../docs/p/name.html
name  = os.path.basename(page)[:-len(".html")]
rows  = [l.split("\t") for l in
         open(os.path.join(os.path.dirname(page), ".order"))
         .read().splitlines() if l]
order = [r[0] for r in rows]
code  = [r[0] for r in rows if r[2] == "code"]
tests = [r[0] for r in rows if r[2] == "tests"]
src   = dict((r[0], r[1]) for r in rows).get(name, name)
group = dict((r[0], r[2]) for r in rows).get(name, "code")
lang, runs = LANG[os.path.splitext(src)[1]]

def badge(alt, img, url=None):
  img = f'<img alt="{alt}" src="{img}">'
  return f'<a href="{url}">{img}</a>' if url else img

BADGES = '<p align="center">\n' + "\n".join([
  badge("home",     f"{B}/🏠-home-gold",
        "https://timm.github.io/src/"),
  badge("src",      f"{B}/src-{PROJ.replace('-', '--')}-black",
        f"{REPO}/tree/main/{PROJ}"),
  badge("code",     f"{B}/code-{len(code)}%20pages-2ea44f",
        f"{code[0]}.html"),
  badge("tests",    f"{B}/tests-{len(tests)}%20pages-06b6d4",
        f"{tests[0]}.html"),
  badge("ci",
        f"{REPO}/actions/workflows/tests-{PROJ}.yml/badge.svg",
        f"{REPO}/actions/workflows/tests-{PROJ}.yml"),
  badge("issues",   f"{B}/issues-report-red",
        f"{REPO}/issues"),
  badge("license",  f"{B}/license-MIT-brightgreen",
        f"{REPO}/blob/main/LICENSE.md"),
  badge("language", f"{B}/language-{lang}-9558B2"),
  badge("runs on",  f"{B}/runs%20on-{runs}-EE4C2C"),
  badge("author",   f"{B}/author-timm-blueviolet",
        "https://timm.fyi"),
]) + "\n</p>"

# SSOT override: if this dir's README has a hand-authored
# <!-- badges -->...<!-- /badges --> block, use it verbatim
# (humans tinker there); else fall back to the generated set.
if os.path.exists("README.md"):
  m = re.search(r"<!-- badges -->(.*?)<!-- /badges -->",
                open("README.md").read(), re.S)
  if m: BADGES = m.group(1).strip()

nav = ""
if name in order:
  i    = order.index(name)
  prev = (f'<a href="{order[i-1]}.html">&lt; prev</a>'
          if i > 0 else "&lt; prev")
  nxt  = (f'<a href="{order[i+1]}.html">next &gt;</a>'
          if i + 1 < len(order) else "next &gt;")
  nav  = f"<p>{prev} | {nxt}</p>"
align = "right" if group == "code" else "left"
style = ("<style>p {text-align:%s} "
         "#section-0 p, #section-1 p {text-align:left}"
         "</style></head>" % align)
ext = os.path.splitext(src)[1]
old = name + (".scm" if ext == ".lisp" else ext)
h1  = (f'<h1><a href="{REPO}/blob/main/{PROJ}/{src}">'
       f'{src}</a></h1>')
s = open(page).read()
s = s.replace("</head>", style, 1)
s = s.replace(f"<title>{old}</title>",
              f"<title>{src}</title>")
s = s.replace(f"<h1>{old}</h1>", h1)
open(page, "w").write(s.replace("<h1", BADGES + nav + "<h1", 1))
