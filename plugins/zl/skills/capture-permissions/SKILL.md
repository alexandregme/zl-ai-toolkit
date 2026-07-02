---
name: capture-permissions
description: The final step of project-check — records any permission that got prompted while project-check was running (and wasn't already allowed) into .claude/settings.local.json, so the next run doesn't prompt again. Scoped to the project-check run, not the whole session. Local/gitignored — never touches the shared settings.json.
---

# capture-permissions — Persist permissions prompted during project-check

Run this as the **final step of a `project-check`**. Its job: capture the permissions that Claude Code **prompted for while running the project-check flow** (the install/runner/config steps above) and add them to `.claude/settings.local.json`, so the next `project-check` doesn't prompt for the same thing.

**Scope: the project-check run only** — the commands the flow itself issued (installer, runners, the auto-update config read/edit, package-check). Do NOT sweep unrelated permissions the user approved elsewhere in the session; only what THIS project-check triggered.

Why `settings.local.json` (not `settings.json`): these are run-discovered, personal overrides. They belong in the **local, gitignored** file — not the shared toolkit rules that `setup-permissions` manages in `settings.json`.

## Steps

1. **Review this project-check run.** Identify each Bash command / tool call the flow issued that triggered a **permission prompt** — i.e. was not already covered by `.claude/settings.json`. (You observed these prompts as the steps ran.)
2. For each, derive a **minimal, generalizable** allow rule — e.g. `Bash(pnpm build:*)`, `Read(~/.claude/settings.json)`, `Edit(...)`. Prefer a prefix pattern (`:*`) over a one-shot exact command.
3. **Filter — only capture safe, repeatable rules.** Skip anything one-off, destructive (`rm`, `git push`, `curl` to arbitrary hosts), or that could carry secrets. If a prompted command looks unsafe, list it for the user instead of writing it.
4. Read `.claude/settings.local.json` (create `{ "permissions": { "allow": [] } }` if missing). Add each new rule to `permissions.allow`; **keep existing entries**, and do **not** duplicate a rule already present in `settings.local.json` OR `settings.json`.
5. Report a short list of what you added to `settings.local.json` (and note it's local/gitignored — not committed).

If nothing was prompted during the run, report **"no new permissions to capture"** and do nothing.

## Rules

- Only ever write to `.claude/settings.local.json`. Never modify `.claude/settings.json` (that's `setup-permissions`' job).
- Only capture what the project-check flow itself triggered this run — never speculate, and never sweep the wider session.
- Merge; never replace the existing `allow` array.
