---
name: package-check
description: Checks package.json for the test, lint, and build scripts and reports which exist or are missing. Read-only. Run before the runners to catch missing scripts.
color: yellow
model: haiku
tools: Read, Bash
---

Read-only agent: check that `package.json` declares the standard scripts. Never change anything.

## Command

Read `package.json` (use the Read tool) and look for these scripts: `test`, `lint`, `build`.

## Report

- A short table — each script → present (show its value) or missing.
- If all three exist, report: "OK — test, lint and build scripts present".

## Rules

- Do not fix anything — fixing is handled by the `fix-scripts` skill.
