---
name: zl-project-check
description: Full project validation — sets up permissions, installs deps, checks package.json scripts, then runs test + lint + build (pnpm) in parallel via the zl runner agents, returning a single scoreboard. Use to validate everything at once after code changes.
---

# zl-project-check — Full project validation

**Execution discipline (applies to every agent dispatched below).** When you dispatch each agent, instruct it to: run one command at a time — NO `;`/`&&`/`|` chaining and NO `echo`/exit-code tricks (chained commands trip permission prompts); read each command's own output. The runners are read-only; only `zl-installer` and the permission setup may modify files.

## 1. Ensure permissions
Invoke the `zl-setup-permissions` skill so the runner commands are allowed. `permissions` hot-reload, so continue straight to step 2 whether or not new rules were added.

## 2. Install & approve builds
Dispatch the `zl-installer` agent: run `pnpm install` and, if pnpm reports ignored build scripts, approve them so builds run cleanly. **Note: this may modify the pnpm build-approval config — `allowBuilds` in `pnpm-workspace.yaml` on pnpm 11+, or `onlyBuiltDependencies`/`ignoredBuiltDependencies` on pnpm 10.**

## 3. Validate scripts
Dispatch `zl-package-check` to confirm `package.json` has the `test`, `lint`, and `build` scripts. Note any missing — the matching runner below is skipped (report it as "missing script", not a failure) and suggest `zl-fix-scripts`.

## 4. Run the runners
For each script that exists, dispatch its runner **in parallel** (a single message with the Agent tool calls):

1. `zl-test-runner` — runs the test suite.
2. `zl-lint-runner` — runs lint (tsc + eslint + prettier).
3. `zl-build-runner` — runs the project build.

## 5. Consolidate
Return **a single scoreboard**:

| Step | Result | Notes |
|---|---|---|
| Permissions | ✅ | rules added or already present |
| Install | ✅ / ❌ | deps OK, or what was approved/changed |
| Scripts | ✅ / ⚠️ | which of test/lint/build are present or missing |
| Test  | ✅ / ❌ / – | summary |
| Lint  | ✅ / ❌ / – | summary |
| Build | ✅ / ❌ / – | summary |

Use `–` for a runner skipped because its script is missing. If an agent does not exist under that name, report which one is missing and continue with the others.
