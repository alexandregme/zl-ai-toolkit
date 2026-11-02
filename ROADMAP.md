# zl-ai-toolkit Roadmap

This list tracks potential improvements. Agents must review and update it when new ideas are discussed or implemented.

---

## First release

1. The workflows ran for the first time on the PR that added them. Check that the merge released v1.1.0, with the tag and the GitHub Release
2. Install the plugin from the private repo with `/plugin update zl@zl-ai-toolkit`: this path hasn't been tested. What was public before the repo became private may have been copied

---

## Fixes

1. `setup-permissions`: remove `Edit(~/.claude/settings.json)`. Settings files are protected, so an `allow` rule doesn't skip the prompt for that write
2. `project-check`, step 1: it edits the global settings "without asking" and "without pausing", which that write doesn't allow in the default mode. Only read the setting, and say how to turn auto-update on if it's off
3. `pr` agent: ask before writing `BREAKING CHANGE`, and never write `!` on its own, because a major is the maintainer's call
4. `codex-check`, `NOT_INSTALLED`: it says `npm install -g @openai/codex`, which installs the CLI and not the missing plugin. Use `/plugin marketplace add openai/codex-plugin-cc` and `/plugin install codex@openai-codex`
5. `codex-check`: the fallback note still says the cache keys versions by commit SHA
6. `project-check`: the description says test, lint and build run in parallel, but lint runs first and alone

---

## Configuration

1. Run `claude plugin validate` in CI and in `release.yml`, so a broken manifest can't become a version
2. Give the repo its own `test`, `lint` and `build` scripts, with tests for `bump-type` and `stamp-changelog`. Today `project-check` run here would report them as missing and offer `fix-scripts`, which adds Vitest and ESLint
3. `marketplace.json`: add the top-level `description`, which is the validator's warning, and update the plugin's description
4. `fix-scripts` and `lint-runner` assume `pnpm lint` fixes in place, but in zljs it only checks. Handle both. `fix-scripts` also adds `--passWithNoTests`, which passes with no tests at all
5. `commit` and `pr` agents: state the 100-character limit on body lines and check for an entry in `[Unreleased]`
6. `capture-permissions`: set `user-invocable: false`, since it only makes sense as the last step of `project-check`. Not `disable-model-invocation`, which would block the call from `project-check`
7. README: mention `ssh-agent` in the prerequisite. Background auto-update never prompts, so a key with a passphrase outside the agent can make it fail silently
8. Clean up: 3 merged remote branches, `delete_branch_on_merge` is off, and the local `feat/component-skills` is superseded
9. `codex.sh`: `resolve_companion` picks the last version alphabetically, so `1.9` beats `1.10`. Sort by date, as the other resolver does. Only 1.0.4 exists today

---

## Decisions

1. `dual-review`: keep or remove. Removing it takes out the skill, `codex-check`, the 3 review agents and `codex.sh`, and with them fixes 4 and 5 and configuration item 9. If it stays, drop "prefer it over the built-in" from the description, so it doesn't compete with the native review skill
2. Don't declare Codex in `dependencies` in `plugin.json`: every use of `zl` would have to install it, and only `dual-review` needs it

---

## Known limits

1. "Read-only" agents are only instructed to be: they have free Bash. The docs don't confirm a restriction such as `Bash(pnpm test)` in `tools`. The documented path is `permissions.deny`, for example for `git push`
2. `main` has no branch protection, so a merge can go through with a red CI. GitHub's free plan probably doesn't offer it on private repos: check the account's plan

---

## Skills

1. `feature-structure`: where each file and rule goes in an app (feature folders, `useState`, slices, hooks, `core/domain`). Section 3 of `component-composition` moves there, and `zljs-check` then requires it. `src/` can't be fixed, because the apps have different roots
2. `component-tests` and `component-check` cite `zl:create-component`, which doesn't exist
3. `component-check`: say whether an explicit `variant` on an icon-only button needs a story
4. `component-tests`: drop `toBeInTheDocument` after a `getByRole`, which already fails when the element is missing, and keep `not.toThrow` only for components that call the callback themselves
5. `component-tests`: decide whether focus classes stay in `Styles`. A story `play` already measures focus, and `Input`, `Select`, `TextArea`, `Radio` and `Error` have class assertions of the kind the maintainer rejected on `Checkbox`
