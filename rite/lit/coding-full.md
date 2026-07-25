# Abstract vs full-text coding

A group like SExMOxBM is an AND: that exact set of
flags fired, no others. Each paper appears in exactly
one group row.

Columns: abs = fired in title+abstract; full-bin =
any single match anywhere in the full text; full-thr
= fired at >=0.5 matches per 1000 words of full text.

Length-normalised term frequency is standard IR
practice (Salton & Buckley 1988); the 0.5 cutoff
itself is ours, not from the literature. Before any
of these numbers reach a paper, sensitivity-check the
cutoff (vary it; show the group table is stable).

22 PDFs with usable text.

## Per-flag agreement, abstract vs full text
(binary = any match; thr = >=0.5 per 1k words)

| flag | abs=y | full-bin=y | full-thr=y | flips abs->thr | flips bin->thr | meaning                                                          |
|------|-------|------------|------------|----------------|----------------|------------------------------------------------------------------|
| SE   | 9     | 22         | 21         | 12             | 1              | software engineering task (defects, testing, requirements, code) |
| MO   | 3     | 21         | 10         | 9              | 11             | multi-objective / search-based optimization                      |
| EX   | 8     | 22         | 18         | 12             | 4              | explanation / interpretability / XAI                             |
| BM   | 5     | 22         | 20         | 15             | 2              | benchmarking / empirical comparison                              |

## Group tables (same 22 papers)

| group       | abstract | full-bin | full-thr |
|-------------|----------|----------|----------|
| SExMOxEXxBM | 0        | 21       | 6        |
| SExEXxBM    | 0        | 1        | 9        |
| EX          | 6        | 0        | 0        |
| SE          | 5        | 0        | 0        |
| none        | 4        | 0        | 0        |
| SExMOxBM    | 0        | 0        | 3        |
| SExBM       | 2        | 0        | 1        |
| SExMOxEX    | 1        | 0        | 1        |
| EXxBM       | 1        | 0        | 1        |
| MOxBM       | 1        | 0        | 0        |
| SExMO       | 1        | 0        | 0        |
| SExEX       | 0        | 0        | 1        |
| BM          | 1        | 0        | 0        |

## Technology facet (same 22 papers; DRAFT, hand-audit while reading)

Topic flags above say which literature a paper is in;
these say how its method works. Full text only
(abstracts under-report methodology).

| tech  | full-bin=y | full-thr=y | meaning                                                            |
|-------|------------|------------|--------------------------------------------------------------------|
| EXACT | 3          | 0          | exact solvers (integer/linear/constraint programming, SAT/SMT)     |
| EVO   | 20         | 3          | evolutionary / genetic / Pareto search (NSGA, SPEA, MOEA/D)        |
| SMBO  | 9          | 2          | sequential model-based optimization (Bayesian, surrogates, SMAC)   |
| SYM   | 17         | 5          | symbolic / rule-based reasoning (trees, rule lists, logic, fuzzy)  |
| AGG   | 4          | 0          | aggregation / scalarization (weighted sums, utility, desirability) |
| NN    | 22         | 22         | neural methods (deep learning, transformers, LLMs)                 |

## Top tf-idf terms per paper (stemmed)

- recent/02 Machine learning and deep learning: janiesch, analytical, market, zschech, drift
- recent/03 Scientific Machine Learning Through Physics–Info: pinn, equation, pde, sciencedirect, raissi
- recent/04 GPT-4 Technical Report: refusal, prompt, sexual, apology, attractiveness
- recent/05 Interpreting Black-Box Models: A Review on Expla: visualis, chamola, scien, explainability, visualisation
- recent/06 A Metaverse: Taxonomy, Components, Applications,: metaverse, conf, proc, avatar, roblox
- recent/08 Sparks of Artificial General Intelligence: Early: chatgpt, door, boat, unguard, exit
- recent/10 Evaluating Large Language Models Trained on Code: codex, vowel, code, return, string
- recent/11 A Survey of Large Language Models: llm, agentic, deepseek, qwen, reward
- recent/12 A survey on large language model based autonomou: llm, agent, renmin, prompt, module
- recent/15 Scaling Instruction-Finetuned Language Models: flan, palm, finetun, davinci, muffin
- recent/19 A Survey on the Explainability of Supervised Mac: ontology, burkart, huber, explainability, petal
- recent/20 Human-in-the-loop machine learning: a state of t: mosqueira, curriculum, teacher, teach, measurer
- recent/21 A Unifying Review of Deep and Shallow Anomaly De: anomaly, proc, conf, ruff, roceeding
- recent/23 A Review on Large Language Models: Architectures: llm, noncommercial, noderivative, chatgpt, bert
- recent/30 TruthfulQA: Measuring How Models Mimic Human Fal: truthfulqa, imitative, truthfulness, truthful, falsehood
- recent/36 GPT (Generative Pre-Trained Transformer)— A Comp: gpt, chatgpt, customer, vellore, lifestyle
- recent/37 Beyond the Imitation Game: Quantifying and extra: cited, aclanthology, bench, cite, gmail
- recent/38 Transfer learning: a friendly introduction: hosna, transductive, malaria, adebiyi, inductive
- recent/39 Can Open Large Language Models Catch Vulnerabili: deepseek, qwen, aime, frac, sqrt
- recent/42 Milestones in Autonomous Driving and Intelligent: vehicle, autonomous, driv, intelligent, transport
- classics/03 Explainable Artificial Intelligence (XAI): Conce: explainability, fusion, simplific, explainable, audience
- classics/11 A Unified Approach to Interpreting Model Predict: shapley, deeplift, shap, lime, additive
