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
