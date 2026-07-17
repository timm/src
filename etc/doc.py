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
import os, re, sys, glob, subprocess

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
      if not line.startswith(CMNT[ext]): break
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

TUT = {".lisp": r"\n#\|\n(.*?)\n\|#\n",
       ".lua":  r"\n--\[\[\n(.*?)\n\]\]\n",
       ".py":   r'\n"""\n(#.*?)\n"""\n'}

def tutpage(path, txt, ext):
  "Tutorial file: markdown stanzas alternate with code."
  bits = re.split(TUT[ext], txt, flags=re.S)
  out = [f"# {os.path.basename(path)}", "", "{% raw %}"]
  for i, b in enumerate(bits):
    b = b.replace("\f", "").strip("\n")
    if not b.strip(): continue
    if i % 2: out += [b, ""]                   # markdown stanza
    else: out += [f"```{LANG[ext]}", b, "```", ""]
  return "\n".join(out + ["{% endraw %}"])

def page(path):
  "Markdown page for one source file."
  ext = os.path.splitext(path)[1]
  txt = open(path).read()
  if ext in TUT and re.search(TUT[ext], txt, re.S):
    return tutpage(path, txt, ext)
  bs  = list(blocks(txt, ext))
  nav = lambda j: " · ".join(
    f"[{t}](#b{i+1})" if i != j else f"**{t}**"
    for i, (t, _, _) in enumerate(bs))
  out = [f"# {os.path.basename(path)}", "", "{% raw %}",
         intro(txt, ext), ""]
  if bs: out += ["---", "", nav(-1), ""]
  else:                     # no section markers: one code block
    lines = txt.splitlines()
    k = 0
    while k < len(lines) and (lines[k].startswith("#!") or
          "vim:" in lines[k] or lines[k].startswith(CMNT[ext])):
      k += 1                # skip the contiguous file header
    while k < len(lines) and not lines[k].strip():
      k += 1
    out += [f"```{LANG[ext]}",
            "\n".join(lines[k:]).rstrip(), "```", ""]
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
    "theme: jekyll-theme-primer\ntitle: timm/src\n"
    "plugins: [jekyll-relative-links]\n")
  rows = []
  for d in sorted(glob.glob("*/")):
    d = d.rstrip("/")
    srcs = [f for f in sorted(glob.glob(f"{d}/*"))
            if os.path.splitext(f)[1] in MARK]
    if d in ("etc", "attic") or not srcs: continue
    os.makedirs(f"{site}/{d}", exist_ok=True)
    files = []
    if os.path.isdir(f"docs/{d}"):   # pycco html: copy verbatim,
      os.makedirs(f"{site}/{d}/docs", exist_ok=True)
      for f in glob.glob(f"docs/{d}/*"):
        base = os.path.basename(f)
        open(f"{site}/{d}/docs/{base}", "w").write(open(f).read())
      order = subprocess.run(         # index them, reading order
        ["sh", "INSTALL.md", "list"], cwd=d, text=True,
        capture_output=True).stdout.split()
      files = [f"- [{b}](docs/{b}.html)"
               for b in (os.path.splitext(f)[0] for f in order)]
    else:                             # no pycco: render md pages
      for f in srcs:
        base = os.path.basename(f)
        open(f"{site}/{d}/{base}.md", "w").write(page(f))
        files += [f"- [{base}]({base}.md)"]
    for f in sorted(glob.glob(f"{d}/*.md")):   # hand-written docs
      base = os.path.basename(f)
      if base not in ("README.md", "INSTALL.md"):  # site copy:
        open(f"{site}/{d}/{base}", "w").write(     # Liquid-escape
          "{% raw %}\n" + open(f).read() + "\n{% endraw %}")
        files += [f"- [{base}]({base})"]
    lead = open(f"{d}/README.md").read().splitlines()[2] \
           if os.path.exists(f"{d}/README.md") else ""
    open(f"{site}/{d}/index.md", "w").write(
      f"# {d}\n\n{lead}\n\n" + "\n".join(files) + "\n")
    rows += [f"| [{d}]({d}/index.md) | {lead} |"]
  style = open("etc/style.md").read()
  open(f"{site}/style.md", "w").write(style)
  if os.path.exists("glossary.md"):   # shared dictionary
    open(f"{site}/glossary.md", "w").write(
      "{% raw %}\n" + open("glossary.md").read()
      + "\n{% endraw %}")
  open(f"{site}/index.md", "w").write("\n".join(
    ["# timm/src", "",
     "One flat dir per idea; prose per block, not per function.",
     "Conventions: [style.md](style.md).",
     "Concepts: [glossary.md](glossary.md).",
     "Source: [github.com/timm/src](https://github.com/timm/src).",
     "", "| idea | what |", "|------|------|"] + rows) + "\n")
  print(f"{site}: {len(rows)} projects")

if __name__ == "__main__":
  main(*sys.argv[1:])
