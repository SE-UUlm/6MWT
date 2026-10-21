<p align="center">
  <img src="app/assets/images/logo.png" alt="Logo showing a walking person" width="320" align="middle">
  <img src="wiki/assets/6mwt-wordmark.svg" alt="6MWT" width="250" align="middle">
</p>

<div align="center">

  [![Latest release](https://img.shields.io/github/v/release/SE-UUlm/6MWT?label=release)](https://github.com/SE-UUlm/6MWT/releases/latest)
  [![License](https://img.shields.io/github/license/SE-UUlm/6MWT)](LICENSE)
  [![Wiki](https://img.shields.io/badge/docs-wiki-blue)](https://github.com/SE-UUlm/6MWT/wiki)
  [![App CI](https://github.com/SE-UUlm/6MWT/actions/workflows/flutter-ci.yml/badge.svg?branch=main)](https://github.com/SE-UUlm/6MWT/actions/workflows/flutter-ci.yml)
  [![Visualizer CI](https://github.com/SE-UUlm/6MWT/actions/workflows/visualizer-ci.yml/badge.svg?branch=main)](https://github.com/SE-UUlm/6MWT/actions/workflows/visualizer-ci.yml)

</div>

The six-minute walk test (6MWT) measures how far a person can walk in six minutes and is commonly used to assess functional exercise capacity.

This repository was developed as part of a Software Engineering project at Ulm University during the 2026 summer semester. Its mobile app records six-minute walk tests, estimates the distance covered and presents the result directly on the device.

Start, instructions and profile entry

<img src="wiki/assets/app-home.png" alt="App home screen" width="220"> <img src="wiki/assets/app-instructions.png" alt="App test instructions" width="220"> <img src="wiki/assets/app-profile.png" alt="App profile entry with synthetic data" width="220">

Walking test, result and history

<img src="wiki/assets/app-walk.png" alt="App during a walk test at Uni Ulm" width="220"> <img src="wiki/assets/app-result.png" alt="App result with synthetic data" width="220"> <img src="wiki/assets/app-history.png" alt="App history with synthetic completed and stopped tests" width="220">

The mobile app provides:

- guided six-minute walk tests on Android and iOS;
- distance estimation using GPS and step data;
- an overview of completed and stopped tests;
- detailed results and optional recording exports.

[Install the app](wiki/App-Installation.md) to perform a six-minute walk test.

Browse [app/](app/README.md) for the mobile application, [tools/](tools/README.md) for development tools and helper scripts, and [data/](data/README.md) for example recordings. See [Development](wiki/Development.md) to work on the code.

The desktop Visualizer is a development tool for inspecting exported sensor data on maps and charts. It can also draw reference paths and replay different distance estimators to compare their behavior.

[Latest Release](https://github.com/SE-UUlm/6MWT/releases/latest) · [Wiki](https://github.com/SE-UUlm/6MWT/wiki)

Authors: **[Moritz Beck](https://github.com/Birkenstab), [Lea-Marie Kindermann](https://github.com/LeaMarieKindermann), [Luca-Marie Jamrosy](https://github.com/lucamariej), [Serhat Kan](https://github.com/Serhat310)**.

Licensed under [GPL-3.0-or-later](LICENSE). UI illustrations and app icons were generated using AI.
Screenshots show the actual interface.

### Documentation

All project documentation is maintained in the [Wiki](https://github.com/SE-UUlm/6MWT/wiki). Its source files live in [`wiki/`](wiki/) and are published automatically.

Please add or update detailed documentation there. Outside `wiki/`, keep only brief entry-point READMEs, linking to the relevant wiki pages.
