# cfx-developer-tools

An 11-skill [Claude Code](https://claude.ai/code) plugin for FiveM and RedM (CFX framework) resource development.

Each skill is a single `SKILL.md` file — no build step, no runtime dependencies. Claude Code reads a skill only when a user message matches its trigger description; everything else stays unloaded.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Skills](https://img.shields.io/badge/skills-11-green.svg)]()
[![Version](https://img.shields.io/badge/version-1.1.0-orange.svg)](.claude-plugin/plugin.json)

---

## Skills

| Skill | What it does | Volatility |
|---|---|---|
| `cfx-resource-scaffolding` | Five-question intake → directory structure, fxmanifest.lua, language boilerplate | medium |
| `cfx-client-server` | RegisterNetEvent, TriggerServerEvent/ClientEvent, exports, callbacks, routing buckets | medium |
| `cfx-database` | oxmysql async queries, parameterized patterns, schema design, mysql-async migration | high |
| `cfx-framework-detect` | Detect ESX / QBCore / Qbox / ox\_core / VORP / RSG from fxmanifest + init patterns | high |
| `cfx-fxmanifest` | Required fields, script declarations, dependencies, NUI wiring, escrow, common mistakes | low |
| `cfx-natives` | Calling conventions, client/server availability, hash optimization, native lookup | low |
| `cfx-nui` | Manifest wiring, Lua↔NUI messaging, focus management, DevTools, framework choices | medium |
| `cfx-performance` | Wait loop rules, dynamic wait, resmon targets, GC pressure, JS/C# tips | medium |
| `cfx-state-bags` | Entity.State / Player.State / GlobalState, replication, change handlers, security | medium |
| `cfx-txadmin` | txAdmin HTTP API resource control, player search, kick via MCP tools | high |
| `cfx-refresh` | Audits all 10 sibling skills for staleness against last-verified dates and upstream releases | low |

High-volatility skills (oxmysql, txAdmin, framework init patterns) are flagged for re-verification every 60 days. `cfx-refresh` automates this check.

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/claude-code) — the CLI or desktop app, not the VS Code extension (different skill schema)
- Node.js ≥ 18 — only needed to run the validation and test tools

---

## Installation

### 1. Clone the plugin

```bash
git clone https://github.com/rolling-codes/cfx-developer-tools.git
# or place it anywhere — the path goes in settings.json below
```

### 2. Register in Claude Code settings

Edit `~/.claude/settings.json` and add the following two entries:

**Under `extraKnownMarketplaces`:**

```json
"cfx-developer-tools-local": {
  "source": {
    "source": "directory",
    "path": "/absolute/path/to/cfx-developer-tools"
  }
}
```

**Under `enabledPlugins`:**

```json
"cfx-developer-tools@cfx-developer-tools-local": true
```

### 3. Restart Claude Code

The plugin loads at session start. After restarting, the 11 skills are active.

---

## Usage

Skills trigger from natural language — no slash commands needed.

| Say something like… | Triggers |
|---|---|
| "Scaffold a new FiveM ESX resource" | `cfx-resource-scaffolding` |
| "How do I send data from client to server?" | `cfx-client-server` |
| "Write an oxmysql query for player inventory" | `cfx-database` |
| "Which framework does this resource use?" | `cfx-framework-detect` |
| "My scripts aren't loading in fxmanifest" | `cfx-fxmanifest` |
| "What native gets the player's position?" | `cfx-natives` |
| "Set up a NUI overlay with Lua callbacks" | `cfx-nui` |
| "Optimize my Wait loop — resmon shows 2ms" | `cfx-performance` |
| "Sync player job across all clients" | `cfx-state-bags` |
| "Restart my resource via txAdmin" | `cfx-txadmin` |
| "Are my CFX skills up to date?" | `cfx-refresh` |

---

## Tools

Three validation layers ship with the pack. All require Node.js and run from the repo root.

```bash
# Structural check: frontmatter fields, name/directory match, valid dates
node tools/validate-pack.js

# 22 behavioral assertions for the cfx-refresh staleness algorithm
node tools/test-cfx-refresh.js
```

Both must exit 0 before tagging a release.

`tools/test-routing.md` is the Layer 1 routing specification — 71 expected behaviors covering trigger tests, boundary tests, Iron Law temptation tests, and cross-skill disambiguation. Execution requires a live Claude Code session; results are recorded in `tools/routing-results/`.

---

## Freshness system

Each skill carries two frontmatter fields:

```yaml
last-verified: 2026-10-03   # ISO date — last time content was checked against live docs
volatility: high             # high | medium | low
```

| Volatility | Stale after |
|---|---|
| `high` | 60 days |
| `medium` | 90 days |
| `low` | 180 days |

Ask Claude *"Are my CFX skills up to date?"* to trigger `cfx-refresh`, which reads every skill's `last-verified` date, computes days elapsed, and cross-references the latest oxmysql and txAdmin GitHub release tags. Bump `last-verified` only after verifying content against live docs or a running server — not for wording edits.

---

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` — all six frontmatter fields required (`name`, `description`, `model`, `allowed-tools`, `last-verified`, `volatility`)
2. Write the description as: Capability + trigger phrases + `NOT for X (cfx-sibling)` boundary clauses
3. Assign `volatility` based on how often the underlying API changes
4. `node tools/validate-pack.js` — must exit 0
5. Add to `[Unreleased]` in `CHANGELOG.md`

See `CLAUDE.md` for the full contributor guide and release checklist.

---

## Origin

Adapted from [TMHSDigital/CFX-Developer-Tools](https://github.com/TMHSDigital/CFX-Developer-Tools) (Cursor rules format, v0.12.0) through the [skill-architect](https://github.com/rolling-codes) six-gate pipeline. Technical content preserved; trigger/boundary descriptions, Iron Laws, Red Flags tables, output format constraints, and the freshness system are new.

---

## License

MIT — see [LICENSE](LICENSE).
