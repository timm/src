"""
## Reproducible randomness

Later demos shuffle and sample, so first: everything random
runs through python's `random`, seeded from `the.seed`
before every test, so any demo reproduces in isolation.

| call | returns | what |
|------|---------|------|
| `shuffle(lst)` | list | all items, seeded-random order |
| `some(lst, k)` | list | k items picked at random |
"""

def test_rand():
  "Seeded shuffle repeats; some() respects k."
  random.seed(1); a = shuffle(list(range(20)))
  random.seed(1); b = shuffle(list(range(20)))
  print(a[:8])
  assert a == b
  assert len(some(a, 5)) == 5
  assert len(some(a, 999)) == 20
