# 6MWT App

Record a six-minute walk with GPS and steps, estimate distance, inspect results and export recordings.

The Android and iOS app guides users through profile entry, preparation, the timed walk and its result. Completed recordings are stored locally and can be reviewed in history or exported as JSON for the desktop Visualizer.

- GPS and available step data feed the primary distance estimate; additional estimators provide live comparisons.
- Raw sensor samples are retained for later inspection and algorithm replay.
- Location access is required to start a test; step recording also depends on permission and sensor availability.

The Flutter implementation lives in `lib/`, automated checks in `test/`, and versioned database snapshots in [drift_schemas/](drift_schemas/README.md). See [Architecture](../wiki/Architecture.md) for component responsibilities and [Data and Tools](../wiki/Data-and-Tools.md) for exports.

Start, instructions and profile entry

<img src="../wiki/assets/app-home.png" alt="App home screen" width="220"> <img src="../wiki/assets/app-instructions.png" alt="App test instructions" width="220"> <img src="../wiki/assets/app-profile.png" alt="App profile entry with synthetic data" width="220">

Walking test, result and history

<img src="../wiki/assets/app-walk.png" alt="App during a walk test at Uni Ulm" width="220"> <img src="../wiki/assets/app-result.png" alt="App result with synthetic data" width="220"> <img src="../wiki/assets/app-history.png" alt="App history with synthetic completed and stopped tests" width="220">

[Installation](../wiki/App-Installation.md) · [Development](../wiki/Development.md) · [Latest Release](https://github.com/SE-UUlm/6MWT/releases/latest)
