"""
## Reading cells

Csv cells arrive as strings. `thing` coerces each one:
"23" becomes an int, "-1e2" a float (csv cells can hide
exponents), "True"/"False" become bools, "?" marks a
missing value, anything else stays text.

| call | returns | what |
|------|---------|------|
| `thing(s)` | int, float, bool, text | coerce one cell |
"""

def test_thing():
  "String coercion round-trip."
  got = [thing(s) for s in
         ["23", "3.14", "-1e2", "True", "False", "?", "abc"]]
  print(got)
  assert got == [23, 3.14, -100.0, True, False, "?", "abc"]
