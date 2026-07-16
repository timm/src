#!/usr/bin/env python3
"""
toc.py: rewrite README.md's <!-- doc-toc --> block with
links to the html doc pages, in .order manifest order
(one page per source file). Run from inside a project dir
(make doc does).
"""
import os, re

PROJ = os.path.basename(os.getcwd())
D    = f"https://timm.github.io/src/{PROJ}/docs"
rows = [l.split("\t") for l in
        open(f"../docs/{PROJ}/.order").read().splitlines()
        if l]
code  = [r[0] for r in rows if r[2] == "code"]
tests = [r[0] for r in rows if r[2] == "tests"]
row   = lambda ps: " |\n".join(f"[{p}]({D}/{p}.html)"
                               for p in ps)
block = ("<!-- doc-toc -->\n"
         f"**Code:**\n{row(code)}\n\n"
         f"**Tests (also the tutorial):**\n{row(tests)}\n"
         "<!-- /doc-toc -->")
s = open("README.md").read()
s = re.sub(r"<!-- doc-toc -->.*<!-- /doc-toc -->",
           block, s, flags=re.S)
open("README.md", "w").write(s)
