---
name: zl-setup-permissions
description: Ensures .claude/settings.json allows the commands the zl runner agents need (pnpm test/lint/build/install, npx vitest/tsc/eslint/prettier), so zl-project-check runs without permission prompts. Idempotent — adds only missing rules.
---

# zl-setup-permissions — Grant runner permissions

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

Steps:
1. Read `.claude/settings.json` (create `{ "permissions": { "allow": [] } }` if missing).
2. Add any rule above not already present to `permissions.allow`; keep all existing entries.
3. Report a clear before/after: which rules you **added** and which were **already present**.

`permissions` in settings.json hot-reload — added rules take effect immediately, no restart needed. The flow continues right away.
