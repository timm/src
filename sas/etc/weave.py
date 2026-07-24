#!/usr/bin/env python3 -B
"""
weave.py: build build/book.md from chapter sources.

Directives, alone on a line, in column one:
  %%file PATH          include a whole file
  %%code PATH NAME     include one def or class from PATH
  %%run  CMD...        run CMD; include its output

Code is included by reference and output is captured at
build time. Hence the printed book cannot drift from the
running system: change the code and the book changes too.
A directive that fails kills the build. That is the point.
"""
import ast, pathlib, subprocess, sys

def code(path, name):
  "Extract one top-level def or class, by name, via ast."
  src = pathlib.Path(path).read_text()
  for node in ast.parse(src).body:
    if getattr(node, "name", None) == name:
      lines = src.splitlines()
      return "\n".join(lines[node.lineno - 1
                             : node.end_lineno])
  sys.exit("weave: no %s in %s" % (name, path))

def run(cmd):
  "Run cmd; return stdout; die loudly on any error."
  p = subprocess.run(cmd, shell=True, text=True,
                     capture_output=True)
  if p.returncode:
    sys.exit("weave: %s\n%s" % (cmd, p.stderr))
  return p.stdout.rstrip()

def weave(text):
  "Expand every directive in one chapter's text."
  out = []
  for line in text.splitlines():
    if line.startswith("%%file "):
      f = line.split()[1]
      out += ["```python",
              pathlib.Path(f).read_text().rstrip(), "```"]
    elif line.startswith("%%code "):
      _, f, name = line.split()
      out += ["```python", code(f, name), "```"]
    elif line.startswith("%%run "):
      cmd = line[6:].strip()
      out += ["```", "$ " + cmd, run(cmd), "```"]
    else:
      out += [line]
  return "\n".join(out)

if __name__ == "__main__":
  txt = "\n\n".join(
    weave(pathlib.Path(c).read_text())
    for c in sys.argv[1:])
  pathlib.Path("build").mkdir(exist_ok=True)
  pathlib.Path("build/book.md").write_text(txt + "\n")
  print("build/book.md: %s lines" % len(txt.splitlines()))
