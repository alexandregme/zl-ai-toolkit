---
name: project-check
description: Full project validation — checks toolkit auto-update, sets up permissions, installs deps, checks package.json scripts, then runs test + lint + build (pnpm) in parallel via the zl runner agents, returning a single scoreboard. Use to validate everything at once after code changes.
---

# project-check — Full project validation

**Execution discipline (applies to every agent dispatched below).** When you dispatch each agent, instruct it to: run one command at a time — NO `;`/`&&`/`|` chaining and NO `echo`/exit-code tricks (chained commands trip permission prompts); read each command's own output. The runners are read-only; only `installer` and the permission setup may modify files.

## 1. Toolkit auto-update (config check)
Before anything else, make sure the toolkit will keep itself current. Read `~/.claude/settings.json` → `extraKnownMarketplaces["zl-ai-toolkit"]`, then:

- **Already `"autoUpdate": true`** → report "on" and continue.
- **`autoUpdate` missing/`false`, OR the `zl-ai-toolkit` entry is absent entirely** → the toolkit won't auto-update. **Do NOT just flag it and move on — ask the user right here** whether to enable it. If they agree, add/complete the entry (create it if absent):
  ```json
  "zl-ai-toolkit": {
    "source": { "source": "github", "repo": "alexandregme/zl-ai-toolkit" },
    "autoUpdate": true
  }
  ```
  Merge into the existing `extraKnownMarketplaces` object — never replace other keys or other marketplaces. If the user declines, note it and continue.
- Note for the user: auto-update installs new versions at Claude Code **startup (a full restart)**, not on `/reload-plugins`.

## 2. Ensure permissions
Invoke the `setup-permissions` skill so the runner commands are allowed.
- If it reports **"✅ permissions ready — no reload needed"** (rules already present, or appended to a file that already existed), continue to step 3.
- If it reports **"⚠️ settings.json was just created"**, **STOP the flow here**: tell the user to restart Claude Code (quit and reopen) and re-run `project-check`. Do NOT dispatch the installer/runners on this run — they wouldn't see the new permissions yet and would trigger permission prompts.

## 3. Install & approve builds
Dispatch the `installer` agent: run `pnpm install` and, if pnpm reports ignored build scripts, approve them so builds run cleanly. **Note: this may modify the pnpm build-approval config — `allowBuilds` in `pnpm-workspace.yaml` on pnpm 11+, or `onlyBuiltDependencies`/`ignoredBuiltDependencies` on pnpm 10.**

## 4. Validate scripts
Dispatch `package-check` to confirm `package.json` has the `test`, `lint`, and `build` scripts. Note any missing — the matching runner below is skipped (report it as "missing script", not a failure). If any script is missing, **offer to run the `fix-scripts` skill to add it, and ask the user before running it** (it writes to `package.json`); do not run `fix-scripts` automatically.

## 5. Run the runners
For each script that exists, dispatch its runner **in parallel** (a single message with the Agent tool calls):

1. `test-runner` — runs the test suite.
2. `lint-runner` — runs lint (tsc + eslint + prettier).
3. `build-runner` — runs the project build.

## 6. Consolidate
Return **a single scoreboard**:

| Step | Result | Notes |
|---|---|---|
| Auto-update | ✅ / ⚠️ | toolkit marketplace `autoUpdate` on, or offered to enable |
| Permissions | ✅ | rules added or already present |
| Install | ✅ / ❌ | deps OK, or what was approved/changed |
| Scripts | ✅ / ⚠️ | which of test/lint/build are present or missing |
| Test  | ✅ / ❌ / – | summary |
| Lint  | ✅ / ❌ / – | summary |
| Build | ✅ / ❌ / – | summary |

Use `–` for a runner skipped because its script is missing. If an agent does not exist under that name, report which one is missing and continue with the others.

## 7. Capture new permissions
Invoke the `capture-permissions` skill: if any command prompted for permission during this run (and wasn't already allowed), it records the safe ones into `.claude/settings.local.json` so the next run doesn't prompt for them. Report what it captured (or "no new permissions to capture").

## 8. Token report

Close with the token accounting for the **isolated subagents** — they're the only steps the harness meters per-component. (Skills run inline in the main thread and aren't separately metered, so they're intentionally left out of this report.) Print the headline first, then the per-agent breakdown.

**8a. Consumption headline (first).** Sum the tokens of every subagent dispatched this run and lead with it:
> **≈ `<total>` tokens consumed by the isolated steps — kept out of the main context.**

**8b. Per-agent breakdown (after).** One table — `agent · tokens · note`:
- `installer`, `package-check`, `test-runner`, `lint-runner`, `build-runner`. Read each one's tokens from its completion line (e.g. `Done (… · 18.2k tokens · …)`); use `–` for any that was skipped.

If a subagent's token count isn't shown in its completion line, say so rather than guessing.
