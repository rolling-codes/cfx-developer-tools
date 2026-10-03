---
name: cfx-refresh
description: >-
  Audit the cfx-developer-tools skill pack for staleness — reads last-verified
  dates and volatility ratings, checks current upstream releases for oxmysql
  and txAdmin, and reports which skills need review. Use when the user asks
  "are these skills up to date", "check cfx skill freshness", "cfx-refresh",
  "oxmysql version check", or "txAdmin version check". NOT for writing FiveM
  resource code (any cfx-* skill); NOT for general dependency audits.
model: haiku
allowed-tools: [Read, Glob, WebFetch]
last-verified: 2026-10-03
volatility: low
---

# CFX Skill Freshness Audit

The CFX ecosystem moves fast — oxmysql, txAdmin, ESX, QBCore, and Qbox all release regularly, and a skill that was accurate six months ago may now document wrong API signatures or deprecated patterns. This skill reads `last-verified` and `volatility` from every sibling skill, then checks upstream release tags for the highest-risk dependencies.

## Iron Law

Always report the actual `last-verified` date found in each skill rather than guessing — stale knowledge stated confidently is worse than flagging uncertainty, and a wrong API pattern copied from a "looks fine" skill causes silent runtime failures that are hard to trace.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "The skills were just written so they're probably fine" | "Just written" isn't a date; without reading `last-verified` you don't know how old the knowledge is | Always read the field; never assume |
| "I'll mark everything OK without fetching upstream" | oxmysql and txAdmin tag new releases frequently; a skill may document an API that changed last release | Fetch GitHub release tags for high-volatility dependencies before marking them current |
| "The pack version number tells me if skills are fresh" | Pack version tracks structural changes; per-skill content freshness is separate | `last-verified` is the per-skill freshness signal; pack version is irrelevant here |
| "I'll skip the upstream fetch if the skill looks recent" | A skill verified yesterday can still reference a broken API if a release shipped between verification and now | Always fetch; cost is one WebFetch call per dependency |
| "I can't reach the GitHub API so I'll mark everything OK" | Network failure means upstream state is unknown — never collapse to OK on fetch error | Mark affected skills WATCH with `upstream: UNABLE_TO_VERIFY`; WATCH is the minimum safe status when upstream cannot be confirmed |

## Staleness thresholds

| Volatility | Flag as stale after |
|---|---|
| `high` | 60 days |
| `medium` | 90 days |
| `low` | 180 days |

## Workflow

1. **Glob all sibling skills** — pattern `skills/*/SKILL.md` from the pack root; there should be 10 siblings
2. **Read each** — extract `last-verified` and `volatility` from the frontmatter YAML block (lines between the two `---` markers)
3. **Compute days since each** — compare `last-verified` against today's date; apply threshold table above
4. **Rank** — `STALE` = past threshold; `WATCH` = within 14 days of threshold; `OK` = comfortably within threshold
5. **Fetch upstream releases** — WebFetch the GitHub API for the two highest-risk dependencies:
   - oxmysql: `https://api.github.com/repos/overextended/oxmysql/releases/latest`
   - txAdmin: `https://api.github.com/repos/tabarra/txAdmin/releases/latest`
   - Extract `tag_name` and `published_at` from each response
6. **Cross-reference** — if `cfx-database` or `cfx-txadmin` show `OK` by date but a new upstream release exists since their `last-verified`, upgrade to `WATCH` with a note naming the new version
7. **Output the report** — see format below

## Output format

```
CFX Skill Freshness Report — <today>

Status  | Skill                  | Last Verified | Days | Volatility | Note
--------|------------------------|---------------|------|------------|------
STALE   | cfx-framework-detect   | 2026-01-01    | 275  | high       | Past 60-day threshold
WATCH   | cfx-database           | 2026-08-15    | 49   | high       | oxmysql v2.10.0 released after last-verified
OK      | cfx-fxmanifest         | 2026-10-03    | 0    | low        | Current

Upstream releases checked:
  oxmysql  latest: v2.10.0  (released 2026-09-01)
  txAdmin  latest: v7.3.0   (released 2026-09-15)
```

## All-OK output

If every skill is within its threshold and no upstream releases postdate their `last-verified`, output:

```
CFX Skill Freshness Report — <today>
All skills current — no action needed.

Upstream releases checked:
  oxmysql  latest: v2.10.0  (released 2026-09-01)  ← within all last-verified dates
  txAdmin  latest: v7.3.0   (released 2026-09-15)  ← within all last-verified dates
```

Do not output the full table when everything is OK — a clean report is signal in itself.

## After the report

For stale or watch skills:
- **Content is provably wrong**: fix the skill body and bump `last-verified` to today
- **Uncertain without a live server**: add a note to the Red Flags table and bump `last-verified` with a comment that live testing is pending
- Run `node tools/validate-pack.js` after any frontmatter edits to confirm all fields remain valid

## Sibling skill list

`cfx-client-server`, `cfx-database`, `cfx-framework-detect`, `cfx-fxmanifest`, `cfx-natives`, `cfx-nui`, `cfx-performance`, `cfx-resource-scaffolding`, `cfx-state-bags`, `cfx-txadmin`
