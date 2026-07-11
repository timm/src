#!/usr/bin/env python3
"""
nav.py docs/NAME.html: inject badges, a grouped TOC and
<prev | next> links into a pycco page, before its first <h1>.

Run from inside a project dir. Page order = `sh INSTALL.md
list`. Code pages (x.lisp) get a TOC of all code pages plus
one "tests" entry; test pages (x-eg.lisp) get a TOC of all
test pages plus one "code" entry. prev/next walk the full
INSTALL.md order.
"""
import os, subprocess, sys

REPO = "https://github.com/timm/src"
B    = "https://img.shields.io/badge"
PROJ = os.path.basename(os.getcwd())

def badge(alt, img, url=None):
  img = f'<img alt="{alt}" src="{img}">'
  return f'<a href="{url}">{img}</a>' if url else img

BADGES = '<p align="center">\n' + "\n".join([
  badge("home",     f"{B}/🏠-home-gold",
        "https://timm.github.io/src/"),
  badge("src",      f"{B}/src-{PROJ.replace('-', '--')}-black",
        f"{REPO}/tree/main/{PROJ}"),
  badge("issues",   f"{B}/issues-report-red",
        f"{REPO}/issues"),
  badge("license",  f"{B}/license-MIT-brightgreen",
        f"{REPO}/blob/main/LICENSE.md"),
  badge("language", f"{B}/language-common%20lisp-9558B2"),
  badge("runs on",  f"{B}/runs%20on-sbcl%20|%20clisp-EE4C2C"),
  badge("author",   f"{B}/author-timm-blueviolet",
        "https://timm.fyi"),
]) + "\n</p>"

page  = sys.argv[1]                      # docs/name.html
name  = page.split("/")[-1][:-len(".html")]
order = [f[:-len(".lisp")] for f in subprocess.run(
           ["sh", "INSTALL.md", "list"], text=True,
           capture_output=True).stdout.split()
         if f.endswith(".lisp")]
code  = [p for p in order if not p.endswith("-eg")]
tests = [p for p in order if p.endswith("-eg")]

def link(p, txt=None):
  txt = txt or p
  return (f"<b>{txt}</b>" if p == name
          else f'<a href="{p}.html">{txt}</a>')

mine, (label, first) = ((tests, ("code", code[0]))
                        if name.endswith("-eg")
                        else (code, ("tests", tests[0])))
toc = " | ".join([link(p) for p in mine] +
                 [link(first, label)])
nav = ""
if name in order:
  i    = order.index(name)
  prev = (f'<a href="{order[i-1]}.html">&lt; prev</a>'
          if i > 0 else "&lt; prev")
  nxt  = (f'<a href="{order[i+1]}.html">next &gt;</a>'
          if i + 1 < len(order) else "next &gt;")
  nav  = f"<p>{prev} | {nxt}</p>"
top = BADGES + f"<p>{toc}</p>" + nav
s = open(page).read()
open(page, "w").write(s.replace("<h1", top + "<h1", 1))
