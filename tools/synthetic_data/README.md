# Synthetic Data

Generate deterministic six-minute walks with exact ground truth for testing distance estimators: varying GPS quality, route geometry, step counter delivery, broken step counters and stride changes.

Run from the repository root; only Python 3.10+ is required:

```sh
python3 tools/synthetic_data/generate.py
```

This replaces `data/synthetic/` with one folder per scenario, each containing an app-style `session.json` and a ground-truth `reference.json`. Open the folder in the Visualizer to compare estimators. The sensor models are simplified: use the results to find failure modes, not to claim real-world accuracy.

[Scenarios, models and benchmarking](../../wiki/Data-and-Tools.md#synthetic-data)
