---
name: setup-permissions
description: Ensures .claude/settings.json allows the commands the zl runner agents need (pnpm test/lint/build/install) plus Read/Edit of the user's global settings.json (auto-update) and ~/.claude.json (workspace-trust check), so project-check runs without permission prompts. Also warns if the workspace isn't trusted (which makes Claude Code ignore the allow rules). Idempotent — adds only missing rules.
---

# setup-permissions — Grant runner permissions

Make sure `.claude/settings.json` `permissions.allow` contains the rules the zl agents need, so they run without prompts. **Merge into the existing arrays — never replace them.**

Required allow rules:
- `Bash(pnpm test:*)`
- `Bash(pnpm lint:*)`
- `Bash(pnpm build:*)`
- `Bash(pnpm install:*)`
- `Read(~/.claude/settings.json)` — the `project-check` auto-update step reads the user's global settings; without this, reading a file outside the project prompts.
- `Edit(~/.claude/settings.json)` — the same step may add the `autoUpdate` entry.
- `Read(~/.claude.json)` — to check this workspace's `hasTrustDialogAccepted` (trust step below).
- `Edit(~/.claude.json)` — to set that flag, only if the user opts in.

Steps:
1. Read `.claude/settings.json`. **Note whether it already existed** — if it is missing you will create it (`{ "permissions": { "allow": [] } }`).
2. Add any rule above not already present to `permissions.allow`; keep all existing entries.
3. Report a clear before/after: which rules you **added** and which were **already present**.
4. **Workspace-trust check.** Read `~/.claude.json` and look at `projects["<absolute cwd>"].hasTrustDialogAccepted` (use the project's absolute path as the key).
   - If `true`: continue.
   - If `false` or absent: **Claude Code IGNORES the allow rules above until this workspace is trusted** — the runners will still prompt. Warn the user, and recommend accepting the **trust dialog** (run Claude Code interactively here and accept — the secure path). You may also **offer** to set `projects["<absolute cwd>"].hasTrustDialogAccepted = true` in `~/.claude.json` (Claude Code documents this as the equivalent); **ask before editing**, change only that one field for THIS project, and never touch other projects or keys.
5. **First-run reload flag.** End your report with one of:
   - If you **just created** `.claude/settings.json` (it did not exist before): **"⚠️ settings.json was just created — restart Claude Code (quit and reopen) before running the installer/runners, or those subagents won't see the new permissions and will prompt."**
   - If the file already existed and you only appended (or nothing was missing): **"✅ permissions ready — no reload needed."**

Why the flag: the main thread hot-reloads `permissions` live, but a **subagent** dispatched later in the SAME session keeps the permission snapshot from session start — so a newly-**created** settings.json reaches subagents (installer/runners) only after a restart. Appending to a file that already existed at session start is fine without a restart.
