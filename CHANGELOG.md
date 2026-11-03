# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.3] - 2026-11-03

### Added

- `zljs-update`: updates `@alexandregme/zljs` and `@alexandregme/zl-quality-kit` to their latest versions in an app and runs `zl-lint init` when the kit changed. It runs lint, test and build before and after the update, so only the errors the update introduced go to the new `update-fixer` agent (Sonnet, write), which fixes the app's code and reruns the failing command for up to 3 rounds, never silencing an error or changing a version. On the branch of a red PR from the `zljs-update` workflow, where the update is already done, it skips the baseline and hands every error to the fixer. The changes stay in the working tree, with a report of what was fixed, what stayed open and what the app needs from zljs
- `update-fixer`: a `Migration` note that moves a test's class assertion to a new zljs class is overridden by `component-composition`: the class assertion is deleted, and the test asserts what the user sees

## [1.0.2] - 2026-11-03

### Added

- `state-management`: validates the state management of the zljs library: Zustand for state shared by components, in `core/state/zustand`, and Redux for business rules, with the store and `ReduxProvider` in `core/state/redux`; the store stays internal, and tests and stories reuse the mock store. Selectors, thunks and actions have no rules yet
- `zljs-check`: starts by finding out if the app is a Next.js app and which router it has, and a Next.js app runs the rules in its own file, `nextjs.md`: wrap the root layout in `RootLayout`, take the providers from `AppProviders` instead of a store, `Provider`, `Toaster` or `Loader` of the app's own, and have a 404 page that renders `NotFound` from zljs, in the app's language
- `zljs-check`: the app must have `@alexandregme/zl-quality-kit` at its latest version, with `prettier.config.mjs` and `stylelint.config.mjs` re-exporting it; a `lint` script that skips `prettier --check` and `stylelint`, or a missing `.stylelintignore` for `coverage` and `.next`, is a warning

### Changed

- `component-check`: a touch target must say how much space its neighbors need, and the rules say how they apply to `Link` and to components exported from `core/next/`
- `component-check`: a component doesn't know who uses it, so its stories, comments and code can't name a component that renders it
- `component-check`: a component with no props and no types of its own needs no types file

## [1.0.1] - 2026-11-02

### Added

- `component-tests`: how to test primitive React components
- `component-check`: validates component folders, stories and accessibility
- `component-composition`: how apps compose zljs components
- `zljs-check`: validates that an app has zljs wired, in its instruction files and in its setup
- Versions: the plugin now has a `version`, and each merge to `main` releases a new one from the PR title
- `ROADMAP.md`, with the review of the configuration

### Changed

- `pr` agent: the title is validated as a Conventional Commit, because it drives the version bump, and the body says which version the merge releases
- `dual-review`: the description says when to use it, so it is picked for a code review
- The marketplace is private. The README has the SSH setup to install it

## [1.0.0] - 2026-11-02

The state of the plugin before versions: runner agents, `project-check`, `dual-review` and the git agents.

[Unreleased]: https://github.com/alexandregme/zl-ai-toolkit/compare/v1.0.3...HEAD
[1.0.3]: https://github.com/alexandregme/zl-ai-toolkit/compare/v1.0.2...v1.0.3
[1.0.2]: https://github.com/alexandregme/zl-ai-toolkit/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/alexandregme/zl-ai-toolkit/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/alexandregme/zl-ai-toolkit/releases/tag/v1.0.0
