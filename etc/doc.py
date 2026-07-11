#!/usr/bin/env python3
"""
doc.py: build the gh-pages site from block-marked sources.

Prose lives per BLOCK, not per function. A block starts at a
section marker in the source:
    python:  #-- Title ----
    lisp:    ;;; ## Title
    lua:     -- ## Title
Comment lines at the top of a block become its prose; the rest
is fenced code. Block 0 is the file's header (docstring or
leading comments): preview and theory before any code.

USAGE: python3 etc/doc.py [outdir]     # default _site
Emits markdown; the gh-pages Jekyll build renders it.
"""
import os, re, sys, glob

MARK = {".py":   re.compile(r"^#--\s*(.*?)\s*-*\s*$"),
        ".lisp": re.compile(r"^;;;\s*##\s*(.*)$"),
        ".lua":  re.compile(r"^--\s*##\s*(.*)$")}
CMNT = {".py": "#", ".lisp": ";", ".lua": "--"}
LANG = {".py": "python", ".lisp": "lisp", ".lua": "lua"}

def intro(txt, ext):
  "File-header (docstring or leading comments), fenced verbatim."
  if ext == ".py":
    body = "\n\n".join(m.group(1).strip() for m in
      re.finditer(r'"""(.*?)"""', txt.split("#--")[0], re.S))
  elif ext == ".lua" and "[[" in txt:            # help = [[ ... ]]
    body = txt[txt.index("[[")+2 : txt.index("]]")].strip()
  else:
    out = []
    for line in txt.splitlines():
      if line.startswith("#!") or "vim:" in line: continue
      if not (line.startswith(CMNT[ext]) or not line.strip()): break
      out += [re.sub(r"^[;#-]+ ?", "", line)]
    body = "\n".join(out).strip()
  return "```text\n" + body + "\n```"

def arty(s):
  "True for figlet-ish comment lines (mostly punctuation)."
  bare = re.sub(r"\s", "", s)
  return bare and sum(not c.isalnum() for c in bare) > len(bare)/2

def blocks(txt, ext):
  "Yield (title, prose, code) per section marker."
  cur = None
  for line in txt.splitlines():
    if m := MARK[ext].match(line):
      if cur: yield cur
      cur = [m.group(1), [], []]
    elif cur:
      c = CMNT[ext]
      if not cur[2] and line.startswith(c) and not arty(line):
        cur[1] += [re.sub(r"^[;#-]+ ?", "", line)]
      elif line.strip() or cur[2]:
        cur[2] += [line]
  if cur: yield cur

def page(path):
  "Markdown page for one source file."
  ext = os.path.splitext(path)[1]
  txt = open(path).read()
  bs  = list(blocks(txt, ext))
  nav = lambda j: " · ".join(
    f"[{t}](#b{i+1})" if i != j else f"**{t}**"
    for i, (t, _, _) in enumerate(bs))
  out = [f"# {os.path.basename(path)}", "", "{% raw %}",
         intro(txt, ext), ""]
  if bs: out += ["---", "", nav(-1), ""]
  for i, (title, prose, code) in enumerate(bs):
    out += [f"## {title} {{#b{i+1}}}", "",
            f"<small>{nav(i)}</small>", "",
            "\n".join(prose).strip(), "",
            f"```{LANG[ext]}",
            "\n".join(code).rstrip(), "```", ""]
  return "\n".join(out + ["{% endraw %}"])

def main(site="_site"):
  os.makedirs(site, exist_ok=True)
  open(f"{site}/_config.yml", "w").write(
    "theme: jekyll-theme-primer\ntitle: timm/src\n")
  rows = []
  for d in sorted(glob.glob("*/")):
    d = d.rstrip("/")
    srcs = [f for f in sorted(glob.glob(f"{d}/*"))
            if os.path.splitext(f)[1] in MARK]
    if d in ("etc", "attic") or not srcs: continue
    os.makedirs(f"{site}/{d}", exist_ok=True)
    files = []
    for f in srcs:
      base = os.path.basename(f)
      open(f"{site}/{d}/{base}.md", "w").write(page(f))
      files += [f"- [{base}]({base}.md)"]
    lead = open(f"{d}/README.md").read().splitlines()[2] \
           if os.path.exists(f"{d}/README.md") else ""
    open(f"{site}/{d}/index.md", "w").write(
      f"# {d}\n\n{lead}\n\n" + "\n".join(files) + "\n")
    rows += [f"| [{d}]({d}/index.md) | {lead} |"]
  style = open("etc/style.md").read()
  open(f"{site}/style.md", "w").write(style)
  open(f"{site}/index.md", "w").write("\n".join(
    ["# timm/src", "",
     "One flat dir per idea; prose per block, not per function.",
     "Conventions: [style.md](style.md).",
     "Source: [github.com/timm/src](https://github.com/timm/src).",
     "", "| idea | what |", "|------|------|"] + rows) + "\n")
  print(f"{site}: {len(rows)} projects")

if __name__ == "__main__":
  main(*sys.argv[1:])
