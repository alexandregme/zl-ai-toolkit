---
name: zl-fix-scripts
description: Adds or fixes the standard test, lint, and build scripts in package.json (pnpm project). Use when zl-package-check reports missing or non-standard scripts.
---

# zl-fix-scripts — Fix package.json scripts

Ensure the project's `package.json` has the scripts below. Add missing ones; for existing ones that differ, show the diff and ask before overwriting.

- `test`: `vitest run --coverage`
- `lint`: `tsc --noEmit && eslint . && prettier --check .` — **check-only** (must NOT auto-fix, so `zl-lint-runner` stays read-only)
- `lint:fix`: `eslint . --fix && prettier --write .` — the writing variant, kept separate
- `build`: **project-specific** (Storybook, Vite, Next.js, tsc, tsup…). Detect from dependencies or ask the owner; never guess silently.

Steps:
1. Read `package.json`.
2. Add missing scripts; for existing ones that differ, show the diff and ask before overwriting.
3. Report a clear before/after: which scripts you **added/fixed** vs which were **already present and correct**.

Rules:
- Only touch the `scripts` section of `package.json`.
- Preserve existing scripts unless clearly wrong; confirm before overwriting.
