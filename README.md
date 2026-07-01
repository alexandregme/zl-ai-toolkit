# zl-ai-toolkit

Private marketplace with the **zl** plugin for Claude Code. Type `/zl` in the terminal to see the whole toolkit.

## Plugin `zl`

Agents and skills to validate a **pnpm** project.

### Agents
Colors group the agents in the terminal: read-only runners are pink, `package-check` is yellow, and the one writer, `installer`, is cyan.

| Agent | Does | Access |
|---|---|---|
| `test-runner` 🩷 | runs `pnpm test`, reports failures | read-only |
| `lint-runner` 🩷 | runs `pnpm lint` (tsc + eslint + prettier) | read-only |
| `build-runner` 🩷 | runs `pnpm build`, reports pass/fail | read-only |
| `package-check` 💛 | checks package.json has test/lint/build scripts | read-only |
| `installer` 🩵 | `pnpm install` + approves ignored build scripts | **write** |

### Skills
- `project-check` — full validation: permissions → install → check scripts → test/lint/build scoreboard.
- `setup-permissions` — allowlists the runner commands in `.claude/settings.json` (hot-reloads, no restart).
- `fix-scripts` — adds/fixes the test/lint/build scripts in `package.json`.

Among the agents, only `installer` writes (see the **Access** column). Two skills also modify files: `setup-permissions` (edits `.claude/settings.json`) and `fix-scripts` (edits `package.json`).

## Install
    /plugin marketplace add alexandregme/zl-ai-toolkit
    /plugin install zl@zl-ai-toolkit --scope user
    /reload-plugins

## Auto-update
The manifest omits `version`, so each `git push` publishes a new commit SHA. Enable auto-update in `~/.claude/settings.json` via `extraKnownMarketplaces`.
