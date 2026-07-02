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
- `project-check` — full validation: auto-update check → permissions → install → check scripts → test/lint/build scoreboard → capture new permissions → token report (per agent; how much stayed out of the main context).
- `setup-permissions` — allowlists the runner commands in `.claude/settings.json`. Appending to an existing file takes effect live; the **first-run create** (file didn't exist) needs one restart before the subagents see the new rules.
- `fix-scripts` — adds/fixes the test/lint/build scripts in `package.json`.
- `capture-permissions` — at the end of a run, records any permission that got prompted during it (and wasn't already allowed) into `.claude/settings.local.json` (Claude Code's personal, un-committed settings file), so the next run doesn't prompt.

Among the agents, only `installer` writes (see the **Access** column). Three skills also modify files: `setup-permissions` (edits `.claude/settings.json`), `fix-scripts` (edits `package.json`), and `capture-permissions` (edits `.claude/settings.local.json`).

## Install

**Prerequisite — private repo over SSH.** Claude Code clones the marketplace over HTTPS, which fails for a private repo with no stored credentials (`fatal: unable to get password from user`). Tell git to use your GitHub SSH key once:

    git config --global url."git@github.com:".insteadOf "https://github.com/"

Then:

    /plugin marketplace add alexandregme/zl-ai-toolkit
    /plugin install zl@zl-ai-toolkit --scope user
    /reload-plugins

## Auto-update
The manifest omits `version`, so each `git push` is a new commit SHA — Claude Code treats every commit as a new version. But **auto-update is OFF by default for private marketplaces**, so `/plugin marketplace update` alone only refreshes the catalog, not the installed plugin.

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
