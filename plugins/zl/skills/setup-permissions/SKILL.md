---
name: setup-permissions
description: Ensures .claude/settings.json allows the commands the zl runner agents need (pnpm test/lint/build/install, npx vitest/tsc/eslint/prettier), so project-check runs without permission prompts. Idempotent — adds only missing rules.
---

# setup-permissions — Grant runner permissions

Make sure `.claude/settings.json` `permissions.allow` contains the rules the zl agents need, so they run without prompts. **Merge into the existing arrays — never replace them.**

Required allow rules:
- `Bash(pnpm test:*)`
- `Bash(pnpm lint:*)`
- `Bash(pnpm build:*)`
- `Bash(pnpm install:*)`
- `Bash(npx vitest:*)`
- `Bash(npx tsc:*)`
- `Bash(npx eslint:*)`
- `Bash(npx prettier:*)`
- `Read(<HOME>/.claude/settings.json)` — the `project-check` auto-update step reads the user's global settings; without this, reading a file outside the project prompts.
- `Edit(<HOME>/.claude/settings.json)` — the same step may add the `autoUpdate` entry.

Replace `<HOME>` with the **absolute** home path (resolve `$HOME`, e.g. `/Users/alex`) — permission globs do NOT expand `~`.

Steps:
1. Read `.claude/settings.json`. **Note whether it already existed** — if it is missing you will create it (`{ "permissions": { "allow": [] } }`).
2. Add any rule above not already present to `permissions.allow`; keep all existing entries.
3. Report a clear before/after: which rules you **added** and which were **already present**.
4. **First-run reload flag.** End your report with one of:
   - If you **just created** `.claude/settings.json` (it did not exist before): **"⚠️ settings.json was just created — reload the session (`/reload` or restart) before running the installer/runners, or those subagents won't see the new permissions and will prompt."**
   - If the file already existed and you only appended (or nothing was missing): **"✅ permissions ready — no reload needed."**

Why the flag: the main thread hot-reloads `permissions` live, but a **subagent** dispatched later in the SAME session keeps the permission snapshot from session start — so a newly-**created** settings.json reaches subagents (installer/runners) only after a reload. Appending to a file that already existed at session start is fine without a reload.
