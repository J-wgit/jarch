# jarch: CI and maintenance review

Reviewed 17 November 2026.

Baseline: `7fe13d3a327273f09d7d6e756afe582be882e839` on `main`.

## Scope and changes

Reviewed the default-branch source tree, repository instructions, package manifests, workflow definitions and up to three recent Actions runs. Source inspection focused on CI entry points and the concrete defects listed below. This is not an exhaustive application-code audit.

- Updated validation checkouts to the verified v7.0.1 commit and setup-python/node/go to v7.1.0 where present. Application runtime/toolchain versions are retained.
- Added a small workflow-syntax job using actionlint 1.7.12, with its installer pinned. ShellCheck and Pyflakes integrations are explicitly disabled; this gate checks workflow syntax, expressions and job configuration.
- Added manual dispatch where absent, explicit read-only validation permissions, workflow-specific cancellation groups and job time bounds where absent. Existing time bounds and deliberate write workflows remain intact.

## Findings and limits

- Only validation workflows changed. The repository-publication workflow repo.yml, its write permissions and its non-cancelling concurrency policy are untouched. Installer checks require disposable Arch/container environments; no host installation was attempted.

## Workflow inventory

| Workflow | Triggers | Jobs and limits |
| --- | --- | --- |
| [ci.yml](workflows/ci.yml) | workflow_dispatch, push, pull_request | shellcheck (60 min), unit (60 min), packages-exist (60 min), packages (60 min), install-base (60 min), install-kde (60 min), install-offline (60 min) |
| [conventions.yml](workflows/conventions.yml) | workflow_dispatch, pull_request | conventions (5 min) |
| [repo.yml](workflows/repo.yml) | push, workflow_dispatch | publish (inherited/default min) |
| [workflow-lint.yml](workflows/workflow-lint.yml) | pull_request, push, workflow_dispatch | actionlint (5 min) |

Path filters and job conditions still apply; a green syntax check alone does not mean every product job ran. Review all applicable jobs, matrix entries, skips and artifacts.

## Evidence

- Local: actionlint 1.7.12 passes for all workflow files. Workflow input compatibility was checked against the official action metadata. This does not execute Actions or install application dependencies.
- Local: application suites were not run except for the focused ai-scm and ttr-client checks described above. Full checkouts are unavailable through the configured Git transport; repository files were inspected through the GitHub connection.
- Hosted: inspect the current PR Checks tab for results at this branch revision. Earlier runs below retain their original revision and do not qualify the maintenance commit.

No earlier Actions runs were returned for this repository.

## Review and use

1. Review the diff and this workflow inventory. Leave this PR unmerged until J reviews it.
2. Inspect PR checks for the exact head revision. Diagnose failures from the failing step/log; distinguish infrastructure, dependency, source-test and convention failures.
3. After merging, rerun applicable workflows from Actions → Run workflow when needed. Manual dispatch becomes available once the workflow is on the default branch; path filters are bypassed by dispatch, but explicit job conditions still apply.
4. Keep local, hosted, browser, VM/hardware and live-provider evidence separate. No release, deployment, merge or live-provider qualification is implied.
5. Start the next product phase from the reviewed merged baseline.
