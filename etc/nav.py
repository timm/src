#!/usr/bin/env python3
"""
nav.py docs/<proj>/NAME.html: inject badges, a grouped TOC
and <prev | next> links into a pycco page, before its first
<h1>.

Pages are per-##-section (see split.py); order, source file
and code/tests grouping come from the .order manifest beside
the page. The <h1> becomes the section name linking to its
source file on github.
"""
import os, sys

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

def link(p):
  return (f"<b>{p}</b>" if p == name
          else f'<a href="{p}.html">{p}</a>')

# toc: one line per source file (newline at file jumps)
mine  = tests if name in tests else code
srcOf = dict((r[0], r[1]) for r in rows)
lines, cur = [], None
for p in mine:
  if srcOf[p] != cur:
    cur = srcOf[p]; lines.append([])
  lines[-1].append(link(p))
toc = "<br>\n".join(" | ".join(l) for l in lines)
nav  = ""
if name in order:
  i    = order.index(name)
  prev = (f'<a href="{order[i-1]}.html">&lt; prev</a>'
          if i > 0 else "&lt; prev")
  nxt  = (f'<a href="{order[i+1]}.html">next &gt;</a>'
          if i + 1 < len(order) else "next &gt;")
  nav  = f"<p>{prev} | {nxt}</p>"
top = BADGES + f"<p>{toc}</p>" + nav
ext = os.path.splitext(src)[1]
old = name + (".scm" if ext == ".lisp" else ext)
h1  = (f'<h1><a href="{REPO}/blob/main/{PROJ}/{src}">'
       f'{src}</a></h1>')
if name != os.path.splitext(src)[0]:
  h1 += f"\n<h2>{name}</h2>"
s = open(page).read()
s = s.replace(f"<title>{old}</title>",
              f"<title>{src}: {name}</title>")
s = s.replace(f"<h1>{old}</h1>", h1)
open(page, "w").write(s.replace("<h1", top + "<h1", 1))
