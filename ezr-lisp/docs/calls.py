"""calls.py file.py: print who-calls-what for top-level defs."""
import ast, sys, textwrap

mod  = ast.parse(open(sys.argv[1]).read())
defs = {n.name: n for n in mod.body
        if isinstance(n, ast.FunctionDef)}

def calls(node): # any use: called, or passed as a value
  out = []
  for x in ast.walk(node):
    if isinstance(x, ast.Name) and isinstance(x.ctx, ast.Load):
      if x.id in defs and x.id != node.name and x.id not in out:
        out.append(x.id)
  return out

print("\n### who calls what\n\n```")
for name, node in defs.items():
  if name.startswith("test_"): continue
  if cs := [c for c in calls(node) if not c.startswith("test_")]:
    print(textwrap.fill(f"{name:<8} -> {' '.join(cs)}", 64,
                        subsequent_indent=" " * 12))
print("```")
