---
name: dual-review
description: Code review of the current diff combining Codex (OpenAI) and Claude. Gates on Codex readiness inline, then runs one OpenAI review (Codex, you choose the model) and one independent Claude review (Opus) in parallel, and a Sonnet merger joins both into one consolidated report returned to the main session. Read-only — never auto-applies fixes.
---

# dual-review — Codex + Claude, merged by Sonnet

One OpenAI review + one Claude review, joined by a Sonnet merger, returned to you. Three isolated subagents keep the work out of the main context:

- `codex-handoff` (**Haiku**) — forwards the diff to Codex and returns **OpenAI's** opinion.
- `claude-reviewer` (**Opus**) — an independent **Claude** review of the same diff (does not see Codex's findings).
- `review-merger` (**Sonnet**) — joins both reviews, adjudicates against the code, and returns the consolidated report.

**Execution discipline (all agents).** Instruct each to run one command at a time — NO `;`/`&&`/`|` chaining. All three are read-only: `codex-handoff` never passes `--write`; `claude-reviewer` and `review-merger` use only read-only git and never edit or commit.

## 1. Parameters

- **Scope** — default `auto` (working-tree if the tree is dirty, else branch vs the detected base). Accept `working-tree` or `branch` as an override.
- **OpenAI model** — default `gpt-5.6`. If the user named a model, pass their slug verbatim (forwarded straight to Codex's `--model`, so any valid slug works). Note: model availability depends on the Codex account/plan — if a slug is rejected (e.g. HTTP 400 on a restricted ChatGPT-login account), fall back to a known-good one like `gpt-5.5` or `gpt-5.4-mini`.

## 2. Readiness gate (inline, before any dispatch)

Run the **`codex-check` skill's check inline** (in the main session) and read its `STATUS=` line by prefix:

- **`STATUS=READY`** prefix → continue to step 3.
- **Anything else** → **STOP the flow here.** Relay the user-facing message `codex-check` maps to that status (`npm install -g @openai/codex` + `/codex:setup`, or `!codex login`) and do **not** dispatch any agent. This gate exists so a not-ready Codex costs zero subagent tokens — the Opus review included.

## 3. Get both opinions — in parallel

Dispatch **`codex-handoff` and `claude-reviewer` together, in a single message** (two Agent tool calls) — they are deliberately independent, and the slow Opus review shouldn't wait for Codex:

- `codex-handoff` — pass the chosen scope and OpenAI model. (It re-checks readiness itself — cheap, and keeps it safe standalone.)
- `claude-reviewer` — pass the same scope. Do **not** pass it Codex's findings (its value is an independent second opinion).

**If `codex-handoff` still comes back with a readiness/error message instead of a review** (e.g. logged out between the gate and the handoff): skip the merger, present **Claude's review alone**, clearly noting the Codex side failed and how to fix it.

## 4. Merge (Sonnet) → main session

Dispatch `review-merger` with the scope, **Codex's raw review** and **Claude's raw review** (step 3). It adjudicates both against the code and returns one consolidated report. Present that report to the user as the result.

**Never auto-apply fixes.** After presenting the report, STOP and ask the user which findings (if any) to fix. Do not edit files as part of this skill.

## 5. Token report

Close with the token accounting for the isolated subagents (the only steps metered per-component; this skill runs inline and isn't metered). Lead with the headline, then the breakdown:

> **≈ `<total>` tokens consumed by the isolated review steps — kept out of the main context.**

One table — `agent · tokens · note` — for `codex-handoff`, `claude-reviewer`, and `review-merger`, reading each one's tokens from its completion line (e.g. `Done (… · 34.4k tokens · …)`). Use `–` for a step that was skipped (e.g. everything skipped because the inline gate stopped the flow). If a count isn't shown, say so rather than guessing.
