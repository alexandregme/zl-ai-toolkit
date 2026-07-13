#!/usr/bin/env bash
# codex.sh — single source of truth for the zl plugin's Codex (OpenAI) integration.
#   codex.sh check                    → readiness check; ALWAYS prints STATUS= and COMPANION= lines
#   codex.sh review <scope> <model>   → runs the read-only adversarial review via the Codex companion
# Used by the codex-check skill and the codex-handoff agent. Keep the
# "always emit a STATUS= line" guarantee — no silent dead-ends.
set -u

resolve_companion() {
  COMPANION=""
  for p in "$HOME"/.claude/plugins/cache/openai-codex/codex/*/scripts/codex-companion.mjs; do
    [ -f "$p" ] && COMPANION="$p"
  done
  if [ -z "$COMPANION" ] && [ -f "$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs" ]; then
    COMPANION="$HOME/.claude/plugins/marketplaces/openai-codex/plugins/codex/scripts/codex-companion.mjs"
  fi
}

cmd_check() {
  resolve_companion
  if [ -z "$COMPANION" ]; then
    echo "STATUS=NOT_INSTALLED"
    echo "COMPANION="
    exit 0
  fi
  OUT=$(node "$COMPANION" setup --json 2>/dev/null) || {
    echo "STATUS=CLI_UNAVAILABLE|setup-failed"
    echo "COMPANION=$COMPANION"
    exit 0
  }
  STATUS=$(CODEX_SETUP_JSON="$OUT" node -e 'try{const j=JSON.parse(process.env.CODEX_SETUP_JSON||"{}");if(!j.codex||!j.codex.available){console.log("STATUS=CLI_UNAVAILABLE|"+((j.codex&&j.codex.detail)||""));}else if(!j.auth||!j.auth.loggedIn){console.log("STATUS=NOT_LOGGED_IN");}else{console.log("STATUS=READY|"+(j.auth.detail||"logged in"));}}catch(e){console.log("STATUS=CLI_UNAVAILABLE|parse-error");}' 2>/dev/null)
  [ -z "$STATUS" ] && STATUS="STATUS=CLI_UNAVAILABLE|no-output"
  echo "$STATUS"
  echo "COMPANION=$COMPANION"
}

cmd_review() {
  scope="${1:?usage: codex.sh review <scope> <model>}"
  model="${2:?usage: codex.sh review <scope> <model>}"
  case "$scope" in
    auto|working-tree|branch) ;;
    *) echo "usage: codex.sh review <auto|working-tree|branch> <model> — got scope '$scope'" >&2; exit 2 ;;
  esac
  resolve_companion
  if [ -z "$COMPANION" ]; then
    echo "STATUS=NOT_INSTALLED"
    exit 1
  fi
  # Read-only by design: never add --write here.
  exec node "$COMPANION" adversarial-review --wait --scope "$scope" --model "$model"
}

case "${1:-}" in
  check) cmd_check ;;
  review) shift; cmd_review "$@" ;;
  *) echo "usage: codex.sh {check|review <scope> <model>}" >&2; exit 2 ;;
esac