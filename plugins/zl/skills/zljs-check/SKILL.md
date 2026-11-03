---
name: zljs-check
description: Use when validating that an app consuming @alexandregme/zljs has it wired correctly — whether its AGENTS.md or CLAUDE.md gives an agent the right instructions for zljs and matches the app's real setup, and whether a Next.js app follows the implementation rules, such as its 404 page. Use after installing or updating zljs, when creating an app, or when an agent in the app imported the wrong package, built its own UI or ignored the composition rules.
---

# zljs-check: Validate that an app has zljs wired

An agent working in an app only knows zljs through the app's instruction files. This skill checks that those files reach the agent, say the right things about zljs, and match what the app really has. In a Next.js app, it also checks how the app is implemented. It reports and changes nothing. These rules are for apps consuming zljs, not for code inside the library.

## Start: what kind of app is it

Do this before anything else, because it decides which rules run.

1. The app's root: the one the user names, default the current directory. It must have `@alexandregme/zljs` in `package.json`; if not, say so and stop.
2. It is a Next.js app when `next` is in `dependencies` or `devDependencies`. Its router comes from the folders on disk: `app/` or `src/app/` is the App Router, `pages/` or `src/pages/` is the Pages Router, and an app can have both.
3. Open the report with the result (`App: Next.js 16.3, App Router (src/app)`, or `App: not Next.js`). A Next.js app also reads `nextjs.md`, next to this file, and runs its rules along with the sections below. Any other app doesn't read it, and the report says so.

## What to read

1. Instruction files: `AGENTS.md` and `CLAUDE.md` in the app, and a `CLAUDE.md` in a parent folder of the same repo, which also loads.
2. The app's real setup: `package.json`, its lockfile, `tsconfig.json`, the global CSS file, and the folders on disk.
3. What zljs really offers: `node_modules/@alexandregme/zljs/package.json` (`version`, `exports`, `peerDependencies`) and `README.md`, in the installed version. Never from memory.

Read a rule against the whole set of files: `Says` is met when any file that loads says it.

## Errors

**The instructions reach the agent**

| Rule | Error when |
|---|---|
| Loaded by Claude Code | The app has `AGENTS.md` and no `CLAUDE.md` with `@AGENTS.md` or the same content. Claude Code loads `CLAUDE.md`, so the file is never read. |
| One source | `AGENTS.md` and `CLAUDE.md` both hold instructions and contradict each other, or a second copy exists (`agents.md`). Say which one is current. |
| References exist | A file or skill it points to doesn't exist from where it is written (`../agents/frontend.md`, `zl:<skill>`). |

**They say the right things about zljs**

| Rule | Error when |
|---|---|
| Package name | It says anything but `@alexandregme/zljs`. `@zljs/core` is the library's internal alias and doesn't resolve in an app. Entry points must match `exports` (`/next`, `/rhf`). |
| zljs first | It doesn't say to use zljs components instead of building UI or raw fields. |
| Composition | It doesn't point to `zl:component-composition`. |
| Library gaps | It doesn't say that a missing prop or color becomes a suggestion for zljs, instead of a change to the package or a workaround in the app. `zl:component-composition` covers it, so the pointer is enough. |
| Updating | It doesn't say to read `node_modules/@alexandregme/zljs/CHANGELOG.md`, or point to the skill that does. |

**They match the app**

Every fact in the files is checked on disk. One row per wrong fact, saying what the file says and what is true.

| Fact | Check against |
|---|---|
| Framework and version, router | `package.json`, `app/` or `pages/` |
| Test runner | `package.json`, `vitest.config.*` or `jest.config.*` |
| Package manager and commands | Lockfile, `scripts` in `package.json`. Two lockfiles is an error too. |
| Folder tree | Every folder it lists exists, and the main folders that exist are listed |
| Install and styles | The setup it describes is the one in the global CSS (see Wiring) |

## Wiring

The setup the files must describe. Each row is an error when the app breaks it, unless the app links a local copy (below).

| Rule | Error when |
|---|---|
| Installed | The installed version doesn't satisfy `package.json`, or the package is missing from `node_modules`. |
| Styles | The global CSS lacks `@import "tailwindcss";` followed by `@import "@alexandregme/zljs/styles.css";`, or that file isn't imported by the root layout. |
| Theme | `--color-zl-*` is redefined before the zljs import. |
| Peers | A peer from `peerDependencies` doesn't resolve from the package, or is out of range. Check the lockfile or `node_modules`, not the app's `package.json`: pnpm installs peers on its own. |
| Imports | The code imports `@zljs/core`, or a path that `exports` doesn't list. |
| Quality kit | `@alexandregme/zl-quality-kit` isn't in `devDependencies`, or the installed version isn't the latest on npm (`npm view @alexandregme/zl-quality-kit version`, never from memory), or `prettier.config.mjs` and `stylelint.config.mjs` don't re-export the kit (`@alexandregme/zl-quality-kit/prettier`, `/stylelint`), or a legacy `.prettierrc*` or `.stylelintrc*` exists next to them. `pnpm exec zl-lint init` writes the files. The kit's ESLint config is optional: a Next.js app may keep `eslint-config-next`. |

**A local copy** (`link:` or a workspace override) needs extra setup, such as `@source`, `transpilePackages` or test aliases, and a path into `core/`. That is not an error, but the files must say it is linked and why, or a later agent removes it. Report the version the link resolves to, because it follows whatever branch the library is on.

## Warnings

- `@source`, `transpilePackages` or a Tailwind `content` path for zljs in an app that doesn't link it: the styles file already scans the library.
- Theme values on a different name (`--color-primary`) when the app means to change a zljs color: only `--color-zl-*` reaches the components.
- zljs facts copied into the file that will go stale, such as a list of components or props: point to the package instead.
- A rule from another skill repeated in full: point to the skill.
- The `lint` script doesn't run `prettier --check` and `stylelint`, so `project-check` can't catch format drift. The kit's own `lint` script runs all three.
- No `.stylelintignore` with `coverage` and `.next`: the kit doesn't ignore them, and a coverage report fails Stylelint with dozens of errors.

## Report

One table per app, opened by what kind of app it is, then what the app needs. Don't fix anything: the user decides.

```
App: Next.js 16.3, App Router (src/app)

| Check | Status | Found |
|---|---|---|
| Loaded by Claude Code | ❌ | AGENTS.md exists, no CLAUDE.md |
| Package name | ❌ | AGENTS.md:15 says @zljs/core, the app imports @alexandregme/zljs |
| Test runner | ❌ | AGENTS.md:13 says Jest, the app has vitest.config.mts |
| Styles | ✅ | src/app/globals.css:1-2 |
| Theme | ⚠️ | src/app/globals.css:5 sets --color-primary, which doesn't reach zljs components |
| 404 page | ❌ | no src/app/not-found.* |
```

Status: ❌ any error, ⚠️ only warnings, ✅ clean. Cite `file:line`. End with the totals (`N ok · N warnings · N errors`).
