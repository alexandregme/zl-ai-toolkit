# zl-ai-toolkit

Open Source marketplace with the **zl** plugin for Claude Code. Type `zl` in the terminal to see the whole toolkit.

## Plugin `zl`

Agents and skills to validate a **pnpm** project.

### Agents
Colors group the agents in the terminal: read-only pnpm runners are pink, `package-check` is yellow, the writers `installer` and `update-fixer` are cyan, the Codex+Claude dual-review trio is purple, and the git write agents (`commit`, `pr`) are green.

| Agent | Does | Access |
|---|---|---|
| `test-runner` 🩷 | runs `pnpm test`, reports failures | read-only |
| `lint-runner` 🩷 | runs `pnpm lint` (tsc + eslint `--fix` + prettier `--write`) — **auto-fixes in place** | read-only agent* |
| `build-runner` 🩷 | runs `pnpm build`, reports pass/fail | read-only |
| `package-check` 💛 | checks package.json has test/lint/build scripts | read-only |
| `installer` 🩵 | `pnpm install` + approves ignored build scripts | **write** |
| `update-fixer` 🩵 | Sonnet: fixes the app's code from the errors a zljs / quality-kit update introduced, reruns the failing command, up to 3 rounds; never silences an error or changes a version | **write** (app code) |
| `codex-handoff` 💜 | Haiku: hands the diff to Codex (OpenAI) for its opinion — checks Codex is installed + logged in first | read-only |
| `claude-reviewer` 💜 | Opus: independent Claude review of the diff (read-only git) | read-only |
| `review-merger` 💜 | Sonnet: joins the Codex + Claude reviews into one consolidated report | read-only |
| `commit` 💚 | reviews the diff and makes one clean Conventional Commit (branches off main first); never pushes | **write** (git) |
| `pr` 💚 | pushes the branch and opens a PR with `gh` (summary + test plan), returns the URL | **write** (git/gh) |

### Skills
- `project-check` — full validation: auto-update check (enables it if off) → permissions → install → check scripts → lint first (it auto-fixes the tree), then test + build in parallel → scoreboard → capture new permissions → token report (per agent; how much stayed out of the main context).
- `setup-permissions` — allowlists the runner commands in `.claude/settings.json`. Appending to an existing file takes effect live; the **first-run create** (file didn't exist) needs one restart before the subagents see the new rules.
- `fix-scripts` — adds/fixes the test/lint/build scripts in `package.json`.
- `capture-permissions` — at the end of a run, records any permission that got prompted during it (and wasn't already allowed) into `.claude/settings.local.json` (Claude Code's personal, un-committed settings file), so the next run doesn't prompt.
- `dual-review` — **Codex + Claude** review of the current diff. Gates on Codex readiness inline (zero subagent tokens if Codex isn't ready), then runs one OpenAI review (Codex — you pick the model, default `gpt-5.6`) and one independent Claude review (Opus) **in parallel**, and a **Sonnet** merger joins both into one consolidated report returned to the main session. Read-only; never auto-applies fixes. Requires the OpenAI `codex` plugin installed **and** logged in (`codex login`) — it checks and tells you if not.
- `codex-check` — readiness gate for the Codex integration: verifies the OpenAI `codex` plugin is installed **and** logged in, emitting a clear status. The logic lives in the shared plugin script `scripts/codex.sh`; the check is run inline as `dual-review`'s gate, re-run by `codex-handoff` before every handoff, and runnable on its own. The single, extensible place to grow pre-review checks.
- `component-tests` — how to test primitive React components: file shape, test order, what goes in `Styles`, and the accessibility layers. About writing code, not validating it.
- `component-check` — validates component folders, stories and accessibility in a library. Fixes file organization; reports accessibility problems without fixing them.
- `component-composition` — how an app composes zljs components: named handlers, no color classes, a suggestion for the library when a color is missing, one folder per step or state.
- `zljs-check` — validates that an app has zljs wired: its `AGENTS.md`/`CLAUDE.md` reach the agent, say the right things about zljs and match the app's real setup. In a Next.js app, it also checks the implementation rules, such as the 404 page. Reports only.
- `state-management` — validates the state management of the zljs library: Zustand for state shared by components, in `core/state/zustand`, and Redux for business rules, with the store and `ReduxProvider` in `core/state/redux`; the store stays internal, and tests and stories reuse the mock store. Reports only.
- `zljs-update` — updates `@alexandregme/zljs` and `@alexandregme/zl-quality-kit` to their latest versions in an app, runs `zl-lint init` when the kit changed, and runs lint, test and build before and after, so only the errors the update introduced go to `update-fixer`. On the branch of a red PR from the `zljs-update` workflow, it fixes every error there. Reports what was fixed, what stayed open and what the app needs from zljs. Goes by the errors, not by the changelog: run `zljs-check` after it for the pending migrations. Leaves the changes in the working tree; never commits.

Among the agents, `installer` and `update-fixer` write files directly (via the Edit tool: the pnpm build-approval keys, and the app's code from an update's error log), and the green git agents write the repo: `commit` stages + commits (branching off `main` first, never pushing) and `pr` pushes + opens a PR via `gh`. `lint-runner` (\*) never hand-edits, but its `pnpm lint` script auto-fixes in place (eslint `--fix` / prettier `--write`), so a lint run can change the working tree. The dual-review agents are read-only (Codex runs read-only; the Claude reviewers use read-only git only). Three skills also modify files: `setup-permissions` (edits `.claude/settings.json`), `fix-scripts` (edits `package.json`), and `capture-permissions` (edits `.claude/settings.local.json`).

## Install

**Prerequisite — private repo over SSH.** Claude Code clones the marketplace over HTTPS, which fails for a private repo with no stored credentials (`fatal: unable to get password from user`). Tell git to use your GitHub SSH key once:

    git config --global url."git@github.com:".insteadOf "https://github.com/"

Then:

    /plugin marketplace add alexandregme/zl-ai-toolkit
    /plugin install zl@zl-ai-toolkit --scope user
    /reload-plugins

## Versions
Each merge to `main` releases a new version, as in zljs: the squash-merged PR title sets the bump (`feat` is a minor, anything else a patch, `type!:` or a `BREAKING CHANGE:` line a major), and the release workflow updates `package.json` and the plugin manifest, moves the `[Unreleased]` entries of `CHANGELOG.md` under the new version, and creates the tag and the GitHub Release. Add each change to `[Unreleased]` in its PR.

## Auto-update
Claude Code finds an update by the `version` in the manifest, so a commit only reaches users when a release changes it. **Auto-update is OFF by default for third-party marketplaces**, so `/plugin marketplace update` alone only refreshes the catalog, not the installed plugin.

To stay up to date automatically, enable auto-update once in `~/.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "zl-ai-toolkit": {
      "source": { "source": "github", "repo": "alexandregme/zl-ai-toolkit" },
      "autoUpdate": true
    }
  }
}
```

At each startup Claude Code then detects a newer version and updates the plugin — you may be prompted to run `/reload-plugins` to load it into the running session.

**Manual update** (without auto-update): `/plugin update zl@zl-ai-toolkit` → `/reload-plugins`.
