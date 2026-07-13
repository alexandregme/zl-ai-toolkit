---
name: code-review
description: Code review of the current diff combining Codex (OpenAI) and Claude. Gets one OpenAI review (Codex, you choose the model) and one independent Claude review (Opus), then a Sonnet merger joins both into one consolidated report returned to the main session. Ensures Codex is installed AND logged in first. Read-only — never auto-applies fixes.
---

# code-review — Codex + Claude, merged by Sonnet

One OpenAI review + one Claude review, joined by a Sonnet merger, returned to you. Three isolated subagents keep the work out of the main context:

- `codex-handoff` (**Haiku**) — forwards the diff to Codex and returns **OpenAI's** opinion.
- `claude-reviewer` (**Opus**) — an independent **Claude** review of the same diff (does not see Codex's findings).
- `review-merger` (**Sonnet**) — joins both reviews, adjudicates against the code, and returns the consolidated report.

**Execution discipline (all agents).** Instruct each to run one command at a time — NO `;`/`&&`/`|` chaining. All three are read-only: `codex-handoff` never passes `--write`; `claude-reviewer` and `review-merger` use only read-only git and never edit or commit.

## 1. Parameters

- **Scope** — default `auto` (working-tree if the tree is dirty, else branch vs the detected base). Accept `working-tree` or `branch` as an override.
- **OpenAI model** — default `gpt-5.6`. If the user named a model, pass their slug verbatim (forwarded straight to Codex's `--model`, so any valid slug works). Note: model availability depends on the Codex account/plan — if a slug is rejected (e.g. HTTP 400 on a restricted ChatGPT-login account), fall back to a known-good one like `gpt-5.5` or `gpt-5.4-mini`.

## 2. Get OpenAI's opinion (Codex) — gate

Dispatch `codex-handoff` with the chosen scope and model. It first checks that Codex is **installed and logged in**.

**Stop on any readiness/error result.** If its output is a readiness message rather than an actual review — i.e. it reports **not-installed**, **CLI-unavailable**, or **not-logged-in** (the ❌ / 🔒 messages `codex-check` defines; a real Codex review never starts with those) — **STOP the flow here.** Relay the instruction to the user (`npm install -g @openai/codex` + `/codex:setup`, or `!codex login`) and do **not** dispatch the other agents. Otherwise keep its output — this is OpenAI's opinion.

## 3. Get Claude's opinion (Opus)

Dispatch `claude-reviewer` with the same scope. It reviews the diff independently — do **not** pass it Codex's findings (its value is an independent second opinion).

## 4. Merge (Sonnet) → main session

Dispatch `review-merger` with the scope, **Codex's raw review** (step 2) and **Claude's raw review** (step 3). It adjudicates both against the code and returns one consolidated report. Present that report to the user as the result.

**Never auto-apply fixes.** After presenting the report, STOP and ask the user which findings (if any) to fix. Do not edit files as part of this skill.

## 5. Token report

Close with the token accounting for the isolated subagents (the only steps metered per-component; this skill runs inline and isn't metered). Lead with the headline, then the breakdown:

> **≈ `<total>` tokens consumed by the isolated review steps — kept out of the main context.**

One table — `agent · tokens · note` — for `codex-handoff`, `claude-reviewer`, and `review-merger`, reading each one's tokens from its completion line (e.g. `Done (… · 34.4k tokens · …)`). Use `–` for a step that was skipped (e.g. both Claude steps skipped because Codex wasn't logged in). If a count isn't shown, say so rather than guessing.
