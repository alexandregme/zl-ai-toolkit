---
name: fix-scripts
description: Adds or fixes the standard test, lint, and build scripts in package.json (pnpm project). Use when package-check reports missing or non-standard scripts.
---

# fix-scripts — Fix package.json scripts

Ensure the project's `package.json` has the scripts below. Add missing ones; for existing ones that differ, show the diff and ask before overwriting.

- `test`: `vitest run --coverage --passWithNoTests` — `--passWithNoTests` is a fallback so a project with no tests **yet** passes the check instead of erroring; it stays harmless once real tests exist.
- `lint`: `tsc --noEmit && eslint . --fix && prettier --write .` — **auto-fixes** (eslint `--fix` + prettier `--write`), so a lint run repairs the repo in place. Non-auto-fixable problems (e.g. unused vars, hook-deps, type errors) still fail the check.
- `build`: **project-specific** (Storybook, Vite, Next.js, tsc, tsup…). Detect from dependencies or ask the owner; never guess silently.

Steps:
1. Read `package.json`.
2. Add missing scripts; for existing ones that differ, show the diff and ask before overwriting.
3. Report a clear before/after: which scripts you **added/fixed** vs which were **already present and correct**.

Rules:
- Only touch the `scripts` section of `package.json`.
- Preserve existing scripts unless clearly wrong; confirm before overwriting.
