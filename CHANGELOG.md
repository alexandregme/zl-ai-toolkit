# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/alexandregme/zl-ai-toolkit/compare/v1.0.1...HEAD
[1.0.1]: https://github.com/alexandregme/zl-ai-toolkit/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/alexandregme/zl-ai-toolkit/releases/tag/v1.0.0
