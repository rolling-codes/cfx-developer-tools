# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Hard Rule — Skill Execution Policy

Skills are lazy-loaded. Nothing runs, reads, or costs tokens unless its trigger condition is explicitly matched by the current task.

- Never pre-load a skill speculatively
- Never keep a skill active between tasks
- Read a SKILL.md once per invocation, then release it
- If no trigger matches, no skill loads
- Routing is stateless and costs nothing — only the matched skill's read costs tokens

This applies to every skill, every subagent, every session. No exceptions.

# Hard Rule — Response Behavior

No AI patterns. Ever.

No formulaic transitions. No symmetrical structure. No generic phrasing. No predictable rhythm. Vary sentence length naturally.

If multiple choice → output only the correct letter.
If short answer → output only the direct answer.
No explanation unless explicitly asked.
No conclusions. No summaries. No filler.

---

# CFX Developer Tools

An 11-skill Claude Code plugin for FiveM and RedM (CFX framework) resource development. No build step — every skill is a single SKILL.md file loaded directly by Claude Code. Registered locally via `extraKnownMarketplaces` in the user's Claude Code settings.

## Commands

```bash
# Structural check: frontmatter fields, name/directory match, valid dates
node tools/validate-pack.js

# 22 behavioral assertions for the cfx-refresh staleness algorithm
node tools/test-cfx-refresh.js
```

Both must exit 0 before tagging a release.

## Architecture

Skills are discovered by Claude Code at session start from the `skills/` directory. Each subdirectory name must match the `name:` field in its SKILL.md — `validate-pack.js` enforces this. Claude Code reads a skill's SKILL.md only when a user message matches its `description:` field; the body (Iron Law, Red Flags table, workflow) is the instruction set executed after loading.

The `cfx-refresh` skill is special: it reads `last-verified` and `volatility` from its 10 siblings, computes staleness against threshold tables, and WebFetches the GitHub API for oxmysql and txAdmin releases. Its algorithm is separately tested in `test-cfx-refresh.js` with a fixed `NOW` constant so assertions never rot as real time advances.

## Frontmatter fields (all required)

```yaml
---
name: cfx-example
description: >-
  One-sentence capability + trigger phrases + boundary NOT clauses.
model: sonnet          # or haiku
allowed-tools: [Read, Grep, Glob]
last-verified: 2026-10-03   # ISO date — last time content was verified against live docs
volatility: medium          # high | medium | low
---
```

| Volatility | Meaning | Stale after |
|---|---|---|
| `high` | API or dep names change often (txAdmin, oxmysql, framework init) | 60 days |
| `medium` | Patterns stable, details evolve (NUI, events, scaffolding) | 90 days |
| `low` | Rarely changes (fxmanifest fields, native calling conventions) | 180 days |

Bump `last-verified` only when technical facts were verified against live docs or a running server — not for wording edits.

## How to add a skill

1. Create `skills/<skill-name>/SKILL.md` — all six frontmatter fields required
2. Assign `volatility` based on how often the underlying API changes
3. Set `last-verified` to today
4. `node tools/validate-pack.js` — must exit 0
5. Add to `[Unreleased]` in `CHANGELOG.md`

## Release checklist

1. `node tools/validate-pack.js` — exit 0
2. `node tools/test-cfx-refresh.js` — exit 0
3. Promote `[Unreleased]` in `CHANGELOG.md` to `[X.Y.Z] - YYYY-MM-DD`
4. Bump `version` in `.claude-plugin/plugin.json`
5. Tag the commit

**Version scheme:** patch = content fixes / `last-verified` bumps; minor = new skills or tooling; major = structural overhaul.
