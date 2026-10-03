# Contributing to cfx-developer-tools

## Adding a skill

1. Create `skills/<skill-name>/SKILL.md` — all six frontmatter fields required:
   ```yaml
   ---
   name: cfx-your-skill
   description: >-
     One sentence covering Capability + Trigger phrases + Boundary (NOT clauses).
   model: sonnet          # sonnet for reasoning tasks, haiku for lookups
   allowed-tools: [Read, Grep, Glob]
   last-verified: 2026-MM-DD
   volatility: medium     # high | medium | low
   ---
   ```

2. Body must include (in order):
   - **Iron Law** — one unconditional rule the skill must never violate
   - **Red Flags table** — 3 rows: `Excuse | Why it's wrong | What to do instead`
   - Workflow / code patterns
   - **Output format** — exact shape of the answer (code block? lead line? both?)

3. Run `node tools/validate-pack.js` — must exit 0.

4. Add an entry under `[Unreleased]` in `CHANGELOG.md`.

## Editing an existing skill

- Fix technical errors or add missing patterns freely.
- Bump `last-verified` **only** when content was verified against live docs or a running server — not for wording edits.
- Re-run `node tools/validate-pack.js` after any frontmatter change.

## Adding a template

Templates live in `templates/<framework>/`. Each needs at minimum:
- `fxmanifest.lua` — with `fx_version`, `games`, and appropriate `dependencies`
- `client/main.lua` (or `.js`)
- `server/main.lua` (or `.js`)
- `config.lua`

Hard rules for templates:
- **Never include `lua54`** — deprecated and ignored by the runtime.
- Use correct framework init pattern (see `skills/cfx-framework-detect/SKILL.md`).
- Server scripts must validate `source` before trusting any client-sent data.

## Adding an example

Examples live in `examples/<name>/` and should demonstrate a complete, working resource. Requirements:
- `fxmanifest.lua` — no `lua54`, no placeholder dependencies
- At minimum client and/or server script showing the pattern end-to-end
- `README.md` explaining what the example demonstrates and any setup steps
- If using oxmysql: include `sql/<name>.sql` with the table schema

## CI checks

Every PR runs `.github/workflows/validate.yml`:
- `node tools/validate-pack.js` — structural checks (frontmatter, name match, dates)
- `node tools/test-cfx-refresh.js` — 22 assertions for the staleness algorithm
- No `lua54` in templates or examples
- Hardcoded credential scan
- All fxmanifest files have `fx_version` and `games`

PRs that fail CI will not be merged.

## Commit format

```
feat: add cfx-vehicles skill
fix: correct Qbox init pattern in cfx-framework-detect
docs: update cfx-nui output format
chore: bump last-verified dates after October audit
```

Types: `feat` (new skill or feature) → minor bump; `fix`/`docs`/`chore` → patch bump; `BREAKING CHANGE` in body → major bump.

## Behavioral validation

The `tools/test-routing.md` file is the Layer 1 behavioral spec — 71 expected behaviors. If you add a new skill or change a trigger description, add tests to this file for your changes. **Do not modify existing tests to match observed behavior** — create a new entry in `tools/routing-results/` documenting what actually happened, then fix the skill if there is a mismatch.
