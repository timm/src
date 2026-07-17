#!/usr/bin/env python3
"""
join.py: the language-agnostic half of a course's --join
check. The concept dictionary (glossary.md) and the lessons
(each course's -eg file) are wired by convention only; this
keeps them honest. Given the glossary and every course's
-eg source, verify: (1) every `glossary.md#key` link lands
on a `## key` heading, and (2) every heading is taught
(linked) by some course. The per-language other half --
dot-list signatures resolve in the module -- stays in each
-eg (it needs that language's reflection). Invoke:

    python3 etc/join.py glossary.md */*-eg.py */*-eg.lua

Prints each dangling link and orphan heading; exits 1 if any.
"""
import re, sys

glossary, srcs = sys.argv[1], sys.argv[2:]
heads = set(re.findall(r"(?m)^## +([\w-]+)", open(glossary).read()))
used  = set()
for f in srcs:
  used |= set(re.findall(r"glossary\.md#([\w-]+)", open(f).read()))

ok = True
for k in sorted(used - heads):            # link to a missing entry
  ok = False; print("no heading:", k)
for k in sorted(heads - used):            # entry no lesson teaches
  ok = False; print("unlinked heading:", k)
print("join: %d headings, %d linked%s" % (
      len(heads), len(used), "" if ok else " -- BROKEN"))
sys.exit(0 if ok else 1)
