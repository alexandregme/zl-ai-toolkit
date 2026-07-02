# zl-ai-toolkit — Agent Configuration

Marketplace repo for the **zl** Claude Code plugin. The plugin bundles agents and skills that validate a **pnpm** project.

## Structure
- `.claude-plugin/marketplace.json` — marketplace catalog.
- `plugins/zl/.claude-plugin/plugin.json` — plugin manifest (**no `version`** → version = commit SHA).
- `plugins/zl/agents/*.md` — subagents: `test-runner`, `lint-runner`, `build-runner`, `package-check`, `installer`.
- `plugins/zl/skills/*/SKILL.md` — skills: `project-check`, `setup-permissions`, `fix-scripts`, `capture-permissions`.

## Conventions
- **Names carry NO prefix** — the plugin namespace does the grouping: skills/agents show as `zl:<name>` (e.g. `zl:project-check`), so typing `zl` in the terminal surfaces the whole toolkit. Do not re-add a `zl-` prefix (it would render as the redundant `zl:zl-...`).
- **Agent colors group them in the terminal:** read-only runners are `pink`, `package-check` is `yellow`, the one writer `installer` is `cyan` (see the color/heart mapping in `README.md`). Write access is signalled by the agent's `tools` and description, not by color.
- **Agents are self-contained and minimal.** Each runner names the single command it may run (`pnpm test`/`lint`/`build`) so it stays disciplined even when dispatched standalone — no splitting `pnpm lint` into `pnpm eslint`, no chaining. `project-check` repeats this discipline when it orchestrates them, and `installer` carries its own (it writes and is often run alone).
- **Read-only agents never edit files or run git.** Only `installer` (pnpm build-approval config), `fix-scripts` (`package.json`), `setup-permissions` (`.claude/settings.json`), and `capture-permissions` (`.claude/settings.local.json`) write.
- **Agents run on `haiku`** (`model: haiku` in frontmatter) — the runners just run one command and report, and the installer's config edits don't need more. Bump an individual agent's model only if it proves insufficient.
- **Assume pnpm.**
- `permissions` in `.claude/settings.json` hot-reload for the main thread, but a **subagent** keeps the permission snapshot from session start — so rules that `setup-permissions` **creates from scratch** this session reach the installer/runners only after a reload. Appending to a file that already existed needs no reload. `project-check` pauses for that reload on the first-run create.

## Releases
No `version` in the manifest → every `git push` publishes a new commit SHA. Installed users get it on demand via `/plugin update zl@zl-ai-toolkit`, or automatically at startup **only if** they set `autoUpdate: true` for the marketplace in `~/.claude/settings.json` (off by default for private marketplaces).

## Commit rules
- Conventional commits. NO co-author / "Generated with" lines. Clean messages.
- Commit only when the maintainer asks.
