#!/usr/bin/env python3
"""
toc.py: rewrite README.md's <!-- doc-toc --> block with
links to the html doc pages, in `sh INSTALL.md list` order.
Run from inside a project dir (make doc does).
"""
import os, re, subprocess

PROJ  = os.path.basename(os.getcwd())
D     = f"https://timm.github.io/src/{PROJ}/docs"
order = [f[:-len(".lisp")] for f in subprocess.run(
           ["sh", "INSTALL.md", "list"], text=True,
           capture_output=True).stdout.split()
         if f.endswith(".lisp")]
code  = [p for p in order if not p.endswith("-eg")]
tests = [p for p in order if p.endswith("-eg")]
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
