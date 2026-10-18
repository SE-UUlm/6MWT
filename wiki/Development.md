# Development

We are using Github issues to track tasks. 

Development follows a simplified Gitflow convention. Feature branches are created from main branch and then merged into main via a Pull Request.

Steps:
* Create Github Issue
* Create Branch from Github Issue. Prefix branch name with `<type>/` e.g. `feat/23-implement-settings`. See [Possible Types](#possible-types) for possible types
* Commit changes on created feature branch. See [Commit Messages](#commit-messages)
* Create Pull Request from feature branch to main branch
* Merge PR if ready and checks passed
* Issue should automatically close

## App and visualizer CI

Checks mean **formatting, static analysis and automated tests**. Workflow files
are in `.github/workflows/`.

| Workflow | Trigger | Checks / builds |
| --- | --- | --- |
| `flutter-ci.yml` | Push (including feature branches) | App checks, for relevant app/CI/SDK changes |
| `flutter-builds.yml` | PR; push to `main` | Android APK + unsigned iOS IPA; relevant changes only on PRs, always on `main` |
| `visualizer-ci.yml` | PR; push to `main` | Visualizer checks; additionally Windows/Linux/macOS builds on `main`; relevant changes only |
| `release-checks.yml` | PR; push to `main` | Shared version validation and release-script tests, when versions or release/CI configuration change |
| `release.yml` | Push of `vX.Y.Z` tag | All app/visualizer checks and all five builds; publish GitHub Release only after success |
| `release.yml` | Manual “Run workflow” | Same checks/builds, without publishing; selected commit must belong to `main` history |

Visualizer-relevant changes include `tools/6mwt_data_visualizer/**`, `app/**`,
`data/**`, release helpers and relevant workflow/SDK configuration. Release runs
never skip work based on changed paths. Build steps are shared through
`build-android.yml`, `build-ios.yml` and `build-visualizer.yml`.

Android uses the debug key on PRs and the permanent keystore on `main` and release
runs. iOS stays unsigned. Actions downloads expire after **7 days**; published
release downloads remain. See [Releases](Releases.md) for setup and tagging.

### Required PR checks

For the `main` ruleset, require `Format`, `Analyze`, `Test`, `Visualizer Format`,
`Visualizer Analyze`, `Visualizer Test`, `Commitlint - all PR commits` and
`PR builds` (source: GitHub Actions). Keep existing security checks as appropriate.
`PR builds` is the stable summary of the Android/iOS builds, including deliberate
skips for unrelated changes; remove the old individual mobile-build requirements.
Do not require main-only desktop builds or the path-filtered `validate` job from
`release-checks.yml`, which does not report a status on every PR. New checks must
run successfully before they appear in GitHub's selection list.

## Useful Commands
* Run code generation: `dart run build_runner build`
    * Needed after changes to riverpod providers and drift database
* Format all code: `dart format .`
* Run linter/code analyzer: `dart analyze`
* Run tests: `flutter test`

For database schema changes, follow [Database Migrations](Database-Migrations.md).

## Commit Messages

We are following [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for our commit messages.

Format: `<type>[optional scope]: <description>`

* Example 1: `feat: implement settings screen`
* Example 2: `docs: add docs for our gps outlier algorithm`

### Possible types:
* **feat**: A new feature for the user, not a new feature for a build script.
* **fix**: A bug fix for the user, not a fix to a build script.
* **docs**: Changes to only the documentation (e.g. Markdown files, inline code comments).
* **test**: Adding missing tests or correcting existing tests (no production code changes).
* **refactor**: A code change that neither fixes a bug nor adds a feature (e.g. rewriting code for readability or structure).
* **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.).
* **perf**: A code change that improves performance.
* **build**: Changes that affect the build system or external dependencies (e.g. Pub, npm, Gradle).
* **ci**: Changes to our CI configuration files and scripts (e.g. GitHub Actions).
* **chore**: Other changes that don't modify src or test files (e.g., updating `.gitignore` or repository maintenance).
* **revert**: Reverts a previous commit. (e.g., `revert: feat: implement settings screen`).

Message Format is checked in CI/CD Pipeline. Last Commit Message can be checked locally using (nodejs required):

```
npx --package @commitlint/cli --package @commitlint/config-conventional commitlint --last --verbose
```
