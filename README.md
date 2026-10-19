# zl-ai-toolkit

Open-source marketplace with the **zl** plugin for Claude Code. Type `zl` in the terminal to see the whole toolkit.

## Plugin `zl`

Agents and skills to validate a **pnpm** project.

### Agents
Colors group the agents in the terminal: read-only pnpm runners are pink, `package-check` is yellow, the pnpm writer `installer` is cyan, the Codex+Claude dual-review trio is purple, and the git write agents (`commit`, `pr`) are green.

| Agent | Does | Access |
|---|---|---|
| `test-runner` 🩷 | runs `pnpm test`, reports failures | read-only |
| `lint-runner` 🩷 | runs `pnpm lint` (tsc + eslint `--fix` + prettier `--write`) — **auto-fixes in place** | read-only agent* |
| `build-runner` 🩷 | runs `pnpm build`, reports pass/fail | read-only |
| `package-check` 💛 | checks package.json has test/lint/build scripts | read-only |
| `installer` 🩵 | `pnpm install` + approves ignored build scripts | **write** |
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

Among the agents, `installer` writes files directly (via the Edit tool), and the green git agents write the repo: `commit` stages + commits (branching off `main` first, never pushing) and `pr` pushes + opens a PR via `gh`. `lint-runner` (\*) never hand-edits, but its `pnpm lint` script auto-fixes in place (eslint `--fix` / prettier `--write`), so a lint run can change the working tree. The dual-review agents are read-only (Codex runs read-only; the Claude reviewers use read-only git only). Three skills also modify files: `setup-permissions` (edits `.claude/settings.json`), `fix-scripts` (edits `package.json`), and `capture-permissions` (edits `.claude/settings.local.json`).

## Install

    /plugin marketplace add alexandregme/zl-ai-toolkit
    /plugin install zl@zl-ai-toolkit --scope user
    /reload-plugins

## Auto-update
The manifest omits `version`, so each `git push` is a new commit SHA — Claude Code treats every commit as a new version. But **auto-update is OFF by default for third-party marketplaces**, so `/plugin marketplace update` alone only refreshes the catalog, not the installed plugin.

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

At each startup Claude Code then detects a newer commit and updates the plugin — you may be prompted to run `/reload-plugins` to load it into the running session.

**Manual update** (without auto-update): `/plugin update zl@zl-ai-toolkit` → `/reload-plugins`.
