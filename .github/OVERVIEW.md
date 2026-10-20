# GitHub automation

Workflows, the shared Flutter version, issue templates and publishing helpers for this repository.

- `workflows/` runs app and Visualizer checks, builds downloads, checks documentation links and publishes releases and the wiki.
- `flutter-version.yaml` pins the Flutter SDK used across CI and release builds.
- `ISSUE_TEMPLATE/` provides templates for bug reports, features and tasks.
- `scripts/prepare_wiki.py` prepares image and repository links for wiki publication

Workflow triggers differ: pull requests receive relevant checks, while release tags run the complete release pipeline. Detailed trigger, signing and artifact-retention rules are documented below.

- [Development and CI](../wiki/Development.md#app-and-visualizer-ci): automated checks and build triggers.
- [Builds and Releases](../wiki/Builds-and-Releases.md): versioning, signing, artifacts and release publication.
- [Wiki publishing](../wiki/Development.md#documentation-checks-and-publishing): link checking and automatic publication from `wiki/`.
