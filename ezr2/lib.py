# Strings and files. `thing` coerces csv cells; `settings`
# parses the help text's "--key = val" lines into `the`;
# `csv` streams typed rows, `path` expanding a leading $MOOT
# (env var, else ~/gits/moot).

# Coerce a string to int/float/bool, else leave as str
def thing(s):
  if (s[1:] if s[:1]=="-" else s).isdigit(): return int(s)
  try: return float(s)
  except ValueError: return s=="True" or (s!="False" and s)

# Parse '--key ... = val' lines of doc into an o()
def settings(doc):
  pat = r"--(\w+)\s+[^=\n]*=\s*(\S+)"
  return o(**{k: thing(v) for k,v in re.findall(pat, doc)})

# Expand a leading $MOOT (env, else ~/gits/moot) and ~
def path(s):
  s = s.replace("$MOOT", MOOT, 1)
  return os.path.expanduser(s)

# Yield typed rows (lists) from a CSV file
def csv(file, clean=lambda s: s.partition("#")[0].split(",")):
  with open(path(file), encoding="utf-8") as f:
    for line in f:
      row = [x.strip() for x in clean(line)]
      if any(row): yield [thing(x) for x in row]
