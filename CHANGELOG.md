# Changelog

All notable changes to this project are documented in this file.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2026-10-03

### Added
- `cfx-refresh` skill — audits all 10 sibling skills for staleness using `last-verified` dates and upstream oxmysql/txAdmin GitHub release tags
- `last-verified: 2026-10-03` and `volatility: high|medium|low` frontmatter fields to all 10 skills
- `CLAUDE.md` — contributor guide: adding skills, updating knowledge, running the validator, release checklist
- `tools/validate-pack.js` — static consistency validator; checks frontmatter fields, name/directory match, valid dates/volatility values; exit 0 on pass
- `tools/test-cfx-refresh.js` — 22 behavioral assertions covering all 8 edge cases: fresh/stale/watch thresholds, upstream-release promotion, upstream-fetch failure (never collapses to OK), malformed frontmatter (error object, never silent skip), determinism

### Changed
- `cfx-natives`: added backtick literal (`` `model` ``) as the preferred compile-time hash form alongside `joaat()`
- `cfx-nui`: clarified that `nui_devtools ResourceName` is an F8 client console command; opens a separate Chromium DevTools window
- `.claude-plugin/plugin.json`: version 1.1.0; description updated to reflect 11 skills

## [1.0.0] - 2026-10-03

### Added
- Initial release: 10 skills adapted from [TMHSDigital/CFX-Developer-Tools](https://github.com/TMHSDigital/CFX-Developer-Tools) through the skill-architect six-gate pipeline
  - `cfx-resource-scaffolding` — 5-question intake → directory structure, fxmanifest, language boilerplate
  - `cfx-client-server` — RegisterNetEvent, TriggerServerEvent/ClientEvent, exports, callbacks, routing buckets
  - `cfx-database` — oxmysql async queries, `@param`/`?` syntax, schema patterns, mysql-async migration
  - `cfx-framework-detect` — fxmanifest dependency → init grep → standalone fallback; ESX/QBCore/Qbox/ox_core/VORP/RSG
  - `cfx-fxmanifest` — required fields, script declarations, dependencies, NUI fields, common mistakes
  - `cfx-natives` — calling conventions (Lua/JS/C#), client/server availability, hash optimization
  - `cfx-nui` — manifest wiring, Lua↔NUI messaging, focus management, framework choices, DevTools
  - `cfx-performance` — Wait loop rules, dynamic wait, resmon targets, event-driven alternatives, JS/C# tips
  - `cfx-state-bags` — Entity.State/Player.State/GlobalState, replication, change handlers, security
  - `cfx-txadmin` — txAdmin HTTP API resource control (start/stop/restart/ensure), player search, kick
- `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`
