# zl-ai-toolkit — Agent Configuration

Marketplace repo for the **zl** Claude Code plugin. The plugin bundles agents and skills that validate a **pnpm** project.

## Structure
- `.claude-plugin/marketplace.json` — marketplace catalog.
- `plugins/zl/.claude-plugin/plugin.json` — plugin manifest (**no `version`** → version = commit SHA).
- `plugins/zl/agents/*.md` — subagents: `zl-test-runner`, `zl-lint-runner`, `zl-build-runner`, `zl-package-check`, `zl-installer`.
- `plugins/zl/skills/*/SKILL.md` — skills: `zl-project-check`, `zl-setup-permissions`, `zl-fix-scripts`.

## Conventions
- **All names carry the `zl-` prefix** — typing `/zl` in the terminal surfaces the whole toolkit. Keep it.
- **Agent colors group them in the terminal:** read-only runners are `pink`, `zl-package-check` is `yellow`, the one writer `zl-installer` is `cyan` (see the color/heart mapping in `README.md`). Write access is signalled by the agent's `tools` and description, not by color.
- **Agents are self-contained and minimal.** Each runner names the single command it may run (`pnpm test`/`lint`/`build`) so it stays disciplined even when dispatched standalone — no splitting `pnpm lint` into `pnpm eslint`, no chaining. `zl-project-check` repeats this discipline when it orchestrates them, and `zl-installer` carries its own (it writes and is often run alone).
- **Read-only agents never edit files or run git.** Only `zl-installer` (pnpm build-approval config), `zl-fix-scripts`, and `zl-setup-permissions` write.
- **Assume pnpm.**
- `permissions` in `.claude/settings.json` hot-reload — no restart needed after `zl-setup-permissions`.

## Releases
No `version` in the manifest → every `git push` to the repo publishes a new commit SHA that auto-updates for installed users.

## Commit rules
- Conventional commits. NO co-author / "Generated with" lines. Clean messages.
- Commit only when the maintainer asks.
