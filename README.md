# zl-ai-toolkit

Private marketplace with the **zl** plugin for Claude Code. Type `/zl` in the terminal to see the whole toolkit.

## Plugin `zl`

Agents and skills to validate a **pnpm** project.

### Agents
Colors group the agents in the terminal: read-only runners are pink, `zl-package-check` is yellow, and the one writer, `zl-installer`, is cyan.

| Agent | Does | Access |
|---|---|---|
| `zl-test-runner` 🩷 | runs `pnpm test`, reports failures | read-only |
| `zl-lint-runner` 🩷 | runs `pnpm lint` (tsc + eslint + prettier) | read-only |
| `zl-build-runner` 🩷 | runs `pnpm build`, reports pass/fail | read-only |
| `zl-package-check` 💛 | checks package.json has test/lint/build scripts | read-only |
| `zl-installer` 🩵 | `pnpm install` + approves ignored build scripts | **write** |

### Skills
- `zl-project-check` — full validation: permissions → install → check scripts → test/lint/build scoreboard.
- `zl-setup-permissions` — allowlists the runner commands in `.claude/settings.json` (hot-reloads, no restart).
- `zl-fix-scripts` — adds/fixes the test/lint/build scripts in `package.json`.

Among the agents, only `zl-installer` writes (see the **Access** column). Two skills also modify files: `zl-setup-permissions` (edits `.claude/settings.json`) and `zl-fix-scripts` (edits `package.json`).

## Install
    /plugin marketplace add alexandregme/zl-ai-toolkit
    /plugin install zl@zl-ai-toolkit --scope user
    /reload-plugins

## Auto-update
The manifest omits `version`, so each `git push` publishes a new commit SHA. Enable auto-update in `~/.claude/settings.json` via `extraKnownMarketplaces`.
