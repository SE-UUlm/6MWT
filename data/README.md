# Example recordings

Recorded six-minute walk tests and reference routes for inspecting sensor data, testing distance estimators and comparing algorithms in the Visualizer.

Each folder groups a walk or comparison scenario. A typical folder contains an app recording (`session.json`) and optional references (`reference.json` or files under `references/`). Folders with several `session_*.json` files group recordings from multiple devices.

Open a folder in the Visualizer to inspect its tracks and replay estimators. **Uni 1** includes both a device reference and a manually drawn route; **Uni together 1** demonstrates a comparison across devices. `synthetic/` contains generated walks with exact ground truth; see [Synthetic Data](../tools/synthetic_data/README.md). References can contain measurement error, and manually drawn routes use assumed timing.


> [!WARNING]
> **Do not dox yourself!**
> - Before adding recordings, review GPS locations and profile information for privacy. Do not commit raw FIT files; use the conversion tools and inspect the resulting JSON before sharing.


See [Data and Tools](../wiki/Data-and-Tools.md) for the folder structure, data formats, privacy guidance and conversion tools, and [Visualizer](../wiki/Visualizer.md) for viewing recordings.
