# Seeded sampling. Both lean on python's `random`, seeded by
# `the.seed` before every test or study so runs reproduce.

# All of lst, in seeded-random order
def shuffle(lst): return random.sample(lst, len(lst))

# K items picked at random
def some(lst, k): return random.sample(lst, min(k, len(lst)))
