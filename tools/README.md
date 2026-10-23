# Project tools

Tools for exploring recordings, preparing reference data and maintaining releases. The Visualizer is a Flutter desktop application; the converters and release helpers are Python scripts.

| Tool | Purpose | Notes | Documentation |
| --- | --- | --- | --- |
| [6MWT Visualizer](6mwt_data_visualizer/README.md) | Inspect recordings, compare reference routes and replay distance estimators. | Open the repository's [example recordings](../data/README.md) for a first look. Development requires the complete checkout because the Visualizer imports estimators from `app/`. | [Installation and use](../wiki/Visualizer.md) · [Development](../wiki/Development.md) |
| [FIT Converter](fit_converter/README.md) | Convert workout FIT files into reference JSON. | Use when adding a watch recording as a reference. | [Data and Tools](../wiki/Data-and-Tools.md#fit-converter) |
| [Synthetic Data](synthetic_data/README.md) | Generate simulated walks with exact ground truth. | Covers GPS, route, step counter and stride scenarios for testing estimators; output goes to `data/synthetic/`. | [Data and Tools](../wiki/Data-and-Tools.md#synthetic-data) |
| [Timestamp Converter](session_timestamps_to_utc/README.md) | Normalize timestamps in older recordings to UTC. | Repairs exports with mixed time bases; it is not part of the routine workflow for new recordings. Only needed for recordings created by old versions of the app and fit_converter. | [Data and Tools](../wiki/Data-and-Tools.md#timestamp-converter) |
| [Release helpers](release/README.md) | Validate versions, configure signing and publish release downloads. | Primarily used by CI. The applicable validation checks can also be run locally before preparing a release. | [Builds and Releases](../wiki/Builds-and-Releases.md) |
