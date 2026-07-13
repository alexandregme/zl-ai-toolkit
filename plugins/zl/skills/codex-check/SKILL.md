---
name: codex-check
description: Readiness check for the Codex (OpenAI) integration — verifies the codex plugin is installed AND that Codex is logged in, before any handoff. Reused by codex-handoff and run inline as the gate of the dual-review skill (also runnable on its own). A single, extensible place to grow pre-review checks over time.
---

# codex-check — is Codex ready?

The one place that answers "can we hand a review to Codex right now?". Run the check, read the `STATUS=` line, and act on it. Designed to be **extended** — add more readiness checks to the script over time (extra tooling, repo state, config), each emitting its own status line.

## The check

The logic lives in the plugin script `scripts/codex.sh` (single source of truth — the `codex-handoff` agent runs the same file). It **always** prints a `STATUS=` line and a `COMPANION=` line — even when `setup --json` fails or emits non-JSON (that's the point: no silent dead-ends).

Run this once (the fallback resolves the installed copy — newest by mtime, since the cache keys versions by commit SHA — for contexts where `CLAUDE_PLUGIN_ROOT` isn't set):

```bash
unsetopt nomatch 2>/dev/null || true
SCRIPT="${CLAUDE_PLUGIN_ROOT:-}/scripts/codex.sh"
if [ ! -f "$SCRIPT" ]; then
  SCRIPT=""
  for p in ~/.claude/plugins/cache/zl-ai-toolkit/zl/*/scripts/codex.sh ~/.claude/plugins/marketplaces/zl-ai-toolkit/plugins/zl/scripts/codex.sh; do
    [ -f "$p" ] || continue
    if [ -z "$SCRIPT" ] || [ "$p" -nt "$SCRIPT" ]; then SCRIPT="$p"; fi
  done
fi
if [ -z "$SCRIPT" ]; then echo "STATUS=CLI_UNAVAILABLE|zl-codex-script-not-found"; echo "COMPANION="; else bash "$SCRIPT" check; fi
```

## How to read the result

Match the `STATUS=` line by **prefix** (the READY line carries a `|<detail>` suffix — never assume an exact string):

- **`STATUS=READY|<detail>`** — good to go. The `COMPANION=<path>` line has the resolved companion path.
- **`STATUS=NOT_INSTALLED`** — the Codex plugin isn't installed:
  > ❌ Codex plugin not found. Install it with `npm install -g @openai/codex`, then run `/codex:setup`, then retry.
- **`STATUS=CLI_UNAVAILABLE|<detail>`** — plugin present but the `codex` CLI can't run (also covers `setup --json` failing / bad output):
  > ❌ Codex CLI unavailable (`<detail>`). Run `npm install -g @openai/codex` and retry.
- **`STATUS=NOT_LOGGED_IN`** — installed but not authenticated:
  > 🔒 Codex is installed but not logged in. Run `!codex login` (or `!codex login --device-auth`) and retry.

Only a `STATUS=READY` **prefix** means proceed. Every other status is a hard stop — do not attempt a Codex handoff.

## Extending later

Add new checks to `scripts/codex.sh`'s `check` subcommand, each printing its own `STATUS_<name>=...` line, and document how to read it here. Keep every check read-only, and keep the "always emit a status line" guarantee (guard anything that can throw).