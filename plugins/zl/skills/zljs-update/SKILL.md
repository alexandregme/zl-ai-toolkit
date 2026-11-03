---
name: zljs-update
description: Use when updating @alexandregme/zljs and @alexandregme/zl-quality-kit in an app to their latest versions — after a zljs release, when zljs-check reports the app outdated, or when the user asks to update zljs or the quality kit. Updates both, reruns lint, test and build, and hands the errors the update introduced to the update-fixer agent, which fixes the app's code until they close or it runs out of rounds. Leaves everything in the working tree; never commits.
---

# zljs-update: Update zljs and the quality kit in an app

Updating is a version change plus whatever it breaks. This skill does the version change, finds out what broke by running the app's own `lint`, `test` and `build`, and gives that error log to the `update-fixer` agent, which fixes the code. It goes by the errors, not by the changelog: a change that still compiles, such as a renamed class or a migration note, is `zl:component-composition`'s job (section "Updating zljs follows the changelog") and `zl:zljs-check` reports it as a pending migration. Run `zl:zljs-check` after this skill.

Nothing is committed. The user reviews the diff and commits when ready.

The same two updates also run weekly on GitHub, through the workflows the kit writes into the app (`zl-quality-kit.yml` on Wednesdays, `zljs-update.yml` on Thursdays, both calling `alexandregme/zl-workflows`): they open a PR with the version change and say what broke, but fix nothing. This skill is the local version that also fixes, so it is what to run on a red PR from them, on that branch.

**Execution discipline (applies to every agent dispatched below).** When you dispatch each agent, instruct it to: run one command at a time — NO `;`/`&&`/`|` chaining and NO `echo`/exit-code tricks (chained commands trip permission prompts); read each command's own output. The runners are read-only; `installer` writes only the pnpm build-approval keys, and `update-fixer` writes only the app's code.

## 1. Start: what is installed and what is out there

1. The app's root: the one the user names, default the current directory. It must have `@alexandregme/zljs` in `package.json`; if not, say so and stop.
2. The installed versions, from `node_modules/@alexandregme/zljs/package.json` and `node_modules/@alexandregme/zl-quality-kit/package.json`. A missing kit isn't an error: step 3 adds it, and the report says so.
3. The latest versions, from `npm view @alexandregme/zljs version` and `npm view @alexandregme/zl-quality-kit version`. Never from memory.
4. When both are already the latest, the update was done before, typically on the branch of a PR from the `zljs-update` workflow. Skip the baseline (step 2) and the update (step 3), run the checks of step 4, and hand every error to the fixer: there is no "before" on that branch, and its only change is the update. Take the old version from the PR title or the base branch's lockfile (`git show <base>:pnpm-lock.yaml`), and say in the report that there was no baseline. When the checks pass too, say so and stop.

Open the report with the versions: `zljs 1.14.0 → 2.1.1 · zl-quality-kit 2.0.0 → 2.1.0`.

## 2. Baseline: what fails before the update

The fixer must touch only what the update broke, and the only way to know that is to run the checks before and after.

1. Dispatch `package-check`. A runner whose script is missing is skipped in both runs and reported as "missing script", never as a failure. Don't run `fix-scripts` here.
2. Dispatch `lint-runner` **alone** and wait for it: in an app whose `lint` script fixes in place, its writes land now, before anything reads the tree.
3. Dispatch `test-runner` and `build-runner` **in parallel** (one message, both Agent calls).
4. Keep every error verbatim, with its command, file and line. This is the **baseline**: errors the app had before the update. They are listed in the report and left alone.

## 3. Update

1. Run `pnpm up @alexandregme/zljs@latest @alexandregme/zl-quality-kit@latest`. When the kit isn't installed, run `pnpm add -D @alexandregme/zl-quality-kit@latest` instead for it. Read the output: peer warnings go in the log for the fixer, and `ERR_PNPM_IGNORED_BUILDS` means dispatching `installer`, which approves the build scripts and installs again.
2. When the kit's version changed or it was just added, run `pnpm exec zl-lint init`. It writes the config files the app lacks, keeps the ones it has, and rewrites the workflow files the kit owns, `.github/workflows/zl-quality-kit.yml` and `zljs-update.yml`. Read its output and keep the `write`/`update` lines for the report.
3. Re-read the two `node_modules/.../package.json` and confirm both are now the latest. If one isn't, say what pnpm installed and why (a range elsewhere in the lockfile, a failed install) and stop before the fixer: fixing against the wrong version is wasted.

## 4. Run again

The same runs as the baseline: `lint-runner` alone, then `test-runner` and `build-runner` in parallel. Keep every error verbatim.

## 5. The update's errors

Compare the two logs. An error that is in the baseline (same command, same file, same message) is the app's and stays out. Everything else is the update's: new errors, and baseline errors whose message changed. Group them by command, in the order the commands ran. Peer warnings from step 3 go in as well.

When the update produced no errors, skip step 6 and say so.

## 6. Fix

Dispatch `update-fixer` **once**, with all of this in its prompt:

- The versions, old and new, of both packages.
- The update's errors, verbatim, grouped by command.
- The baseline errors, verbatim, marked as "leave alone".
- Which of `lint`, `lint:fix`, `test` and `build` exist in `package.json`.

It fixes the app's code, reruns the command that produced each error, and goes up to 3 rounds. Its last round runs every existing command, so its report is the final state of the app: don't dispatch the runners again after it. Don't dispatch it a second time either: what it reports as open goes to the user.

## 7. Report

One scoreboard, then the details.

| Step | Result | Notes |
|---|---|---|
| Versions | ✅ / ⚠️ | `zljs 1.14.0 → 2.1.1 · zl-quality-kit 2.0.0 → 2.1.0`, or which one didn't reach the latest and why |
| Baseline | ✅ / ⚠️ / – | N errors the app already had (left alone), or `–` when the app was green |
| Install | ✅ / ❌ | deps OK, build scripts approved, or what failed |
| zl-lint init | ✅ / – | files written or updated, or `–` when the kit didn't change |
| Update errors | ✅ / ❌ | N errors the update introduced, by command |
| Fixer | ✅ / ⚠️ / – | N fixed, N open after N rounds, or `–` when there was nothing to fix |
| Lint / Test / Build | ✅ / ❌ / – | the final state, from the fixer's last round or from step 4 when it didn't run |

Then:

- **Open errors**, verbatim, each with why the fixer left it, so the user can take over.
- **Baseline errors**, verbatim, as a reminder that they predate the update.
- **Suggestions for zljs** the fixer raised: a prop, a color or a component the app needed and the library lacks. They become issues or PRs on zljs, not workarounds in the app.
- **Files changed**: `git status --short`, read-only.
- **Next**: review the diff; run `zl:zljs-check` for the pending migrations and the instruction files; commit when ready (`zl:commit`). Nothing was committed.

## 8. Capture new permissions

Invoke the `capture-permissions` skill for this run: `pnpm up`, `pnpm add`, `pnpm exec zl-lint init` and `npm view` may have prompted the first time. Report what it captured, or "no new permissions to capture".

## 9. Token report

Close as `project-check` does: the total of every subagent dispatched this run first, then one line per agent (`package-check`, `lint-runner` ×2, `test-runner` ×2, `build-runner` ×2, `installer`, `update-fixer`), with `–` for any that was skipped. If a completion line doesn't show the count, say so rather than guessing.
