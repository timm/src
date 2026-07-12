#!/usr/bin/env python3
"""
nav.py docs/NAME.html: inject badges, a grouped TOC and
<prev | next> links into a pycco page, before its first <h1>.

Run from inside a project dir. Page order = `sh INSTALL.md
list`. Code pages get a TOC of the code pages; -eg pages a
TOC of the -eg pages; the badge strip carries "code" and
"tests" links to each group's first page plus the dir's own
live ci badge. Also retitles the page to its true source
name and links the <h1> to the file on github.
"""
import os, subprocess, sys

REPO = "https://github.com/timm/src"
B    = "https://img.shields.io/badge"
PROJ = os.path.basename(os.getcwd())
EXTS = (".lisp", ".py", ".lua")
LANG = {".lisp": ("common%20lisp", "sbcl%20|%20clisp"),
        ".py":   ("python", "python3"),
        ".lua":  ("lua", "lua5.4")}

page  = sys.argv[1]                      # docs/name.html
name  = page.split("/")[-1][:-len(".html")]
srcs  = [f for f in subprocess.run(
           ["sh", "INSTALL.md", "list"], text=True,
           capture_output=True).stdout.split()
         if f.endswith(EXTS)]
stem  = lambda f: os.path.splitext(f)[0]
order = [stem(f) for f in srcs]
code  = [p for p in order if not p.endswith("-eg")]
tests = [p for p in order if p.endswith("-eg")]
src   = {stem(f): f for f in srcs}.get(name, name)
lang, runs = LANG[os.path.splitext(src)[1]]

def badge(alt, img, url=None):
  img = f'<img alt="{alt}" src="{img}">'
  return f'<a href="{url}">{img}</a>' if url else img

BADGES = '<p align="center">\n' + "\n".join([
  badge("home",     f"{B}/🏠-home-gold",
        "https://timm.github.io/src/"),
  badge("src",      f"{B}/src-{PROJ.replace('-', '--')}-black",
        f"{REPO}/tree/main/{PROJ}"),
  badge("code",     f"{B}/code-{len(code)}%20files-2ea44f",
        f"{code[0]}.html"),
  badge("tests",    f"{B}/tests-{len(tests)}%20files-06b6d4",
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

mine = tests if name.endswith("-eg") else code
toc  = " | ".join(link(p) for p in mine)
nav  = ""
if name in order:
  i    = order.index(name)
  prev = (f'<a href="{order[i-1]}.html">&lt; prev</a>'
          if i > 0 else "&lt; prev")
  nxt  = (f'<a href="{order[i+1]}.html">next &gt;</a>'
          if i + 1 < len(order) else "next &gt;")
  nav  = f"<p>{prev} | {nxt}</p>"
top = BADGES + f"<p>{toc}</p>" + nav
old = (f"{name}.scm" if src.endswith(".lisp")
       else os.path.basename(src))
s = open(page).read()
s = s.replace(f"<title>{old}</title>", f"<title>{src}</title>")
s = s.replace(f"<h1>{old}</h1>",
              f'<h1><a href="{REPO}/blob/main/{PROJ}/'
              f'{src}">{src}</a></h1>')
open(page, "w").write(s.replace("<h1", top + "<h1", 1))
