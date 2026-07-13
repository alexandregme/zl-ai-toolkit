---
name: codex-check
description: Readiness check for the Codex (OpenAI) integration — verifies the codex plugin is installed AND that Codex is logged in, before any handoff. Reused by codex-handoff (and runnable on its own). A single, extensible place to grow pre-review checks over time.
---

# codex-check — is Codex ready?

The one place that answers "can we hand a review to Codex right now?". Run its check, read the `STATUS=` line, and act on it. Designed to be **extended** — add more readiness checks here over time (extra tooling, repo state, config), each emitting its own status line.

## The check

Run this once. It **always** prints a `STATUS=` line and a `COMPANION=` line — even when `setup --json` fails or emits non-JSON (that's the point: no silent dead-ends). It uses a glob (not `ls` parsing) so paths with spaces don't word-split, and guards the JSON parse in a try/catch:

```bash
COMPANION=""
for p in ~/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs; do [ -f "$p" ] && COMPANION="$p"; done
[ -z "$COMPANION" ] && [ -f ~/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs ] && COMPANION="$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs"
if [ -z "$COMPANION" ]; then echo "STATUS=NOT_INSTALLED"; echo "COMPANION="; exit 0; fi
OUT=$(node "$COMPANION" setup --json 2>/dev/null) || { echo "STATUS=CLI_UNAVAILABLE|setup-failed"; echo "COMPANION=$COMPANION"; exit 0; }
STATUS=$(CODEX_SETUP_JSON="$OUT" node -e 'try{const j=JSON.parse(process.env.CODEX_SETUP_JSON||"{}");if(!j.codex||!j.codex.available){console.log("STATUS=CLI_UNAVAILABLE|"+((j.codex&&j.codex.detail)||""));}else if(!j.auth||!j.auth.loggedIn){console.log("STATUS=NOT_LOGGED_IN");}else{console.log("STATUS=READY|"+(j.auth.detail||"logged in"));}}catch(e){console.log("STATUS=CLI_UNAVAILABLE|parse-error");}' 2>/dev/null)
[ -z "$STATUS" ] && STATUS="STATUS=CLI_UNAVAILABLE|no-output"
echo "$STATUS"
echo "COMPANION=$COMPANION"
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

Add new checks below the existing one, each printing its own `STATUS_<name>=...` line, and document how to read it here. Keep every check read-only, and keep the "always emit a status line" guarantee (guard anything that can throw).
