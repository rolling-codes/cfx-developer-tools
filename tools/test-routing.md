# Claude Code Skill Routing Test Matrix

## Purpose

Layer 1 routing specification for the cfx-developer-tools plugin.

This file defines expected behavior; it does not constitute live-session
validation. Execution requires Claude Code with the plugin loaded and active.

Separation of concerns:
- `tools/validate-pack.js` — structural gate (fields, dates, names)
- `tools/test-cfx-refresh.js` — algorithmic gate (staleness logic)
- `tools/test-routing.md` — behavioral specification (routing, constraints, output shape)

Live results are recorded in `tools/routing-results/` (one file per run, named
`YYYY-MM-DD-vX.Y.Z.md`) so test expectations remain independent of execution
outcomes and regressions are traceable.

---

## Test Status

- Matrix version: 1.0.0
- Skills covered: 11
- Live execution: NOT RUN
- Last matrix review: 2026-10-03

---

## Result Vocabulary

| Code | Meaning |
|---|---|
| `PASS` | Expected skill behavior observed |
| `FAIL` | Wrong skill, missing skill, violated constraint, or wrong output shape |
| `CO-LOAD` | Sibling skill loaded unexpectedly alongside the expected skill |
| `MISS` | Expected skill did not activate |
| `BLOCK` | Iron Law or constraint correctly prevented the tempting action |
| `AMBIG-OK` | Prompt was ambiguous; skill correctly asked a clarifying question |
| `N/A` | Test could not be evaluated in this run |

---

## cfx-resource-scaffolding

### Trigger tests

#### RS-T01
Prompt:
> Scaffold a new FiveM resource for me. It will be ESX-based and use Lua.

Expected skill: `cfx-resource-scaffolding`

Expected output:
Five-question intake triggered, collecting: resource name, game target,
language, framework, and database need. Files generated only after all five
answers are collected.

Expected sibling skills:
- none

---

#### RS-T02
Prompt:
> Create a brand-new resource structure from scratch with fxmanifest and boilerplate scripts.

Expected skill: `cfx-resource-scaffolding`

Expected output:
Intake questions asked before any file is generated.

Expected sibling skills:
- none

---

#### RS-T03
Prompt:
> Generate a QBCore resource with oxmysql support and a JavaScript runtime.

Expected skill: `cfx-resource-scaffolding`

Expected output:
Intake confirms the provided framework (QBCore) and database (yes), asks
for remaining missing fields, then generates manifest + boilerplate.

Expected sibling skills:
- `cfx-framework-detect` — only if framework identification is ambiguous from
  the prompt and requires reading existing project files

---

### Boundary tests

#### RS-B01
Prompt:
> I already have a resource. Help me fix the fxmanifest.lua — scripts aren't loading.

Must NOT primarily activate: `cfx-resource-scaffolding`

Expected primary skill: `cfx-fxmanifest`

Expected sibling skills:
- none

---

#### RS-B02
Prompt:
> Add a NUI overlay to my existing resource.

Must NOT primarily activate: `cfx-resource-scaffolding`

Expected primary skill: `cfx-nui`

Expected sibling skills:
- none

---

### Iron Law temptation

#### RS-I01
Prompt:
> I already told you the framework is ESX; just generate the files now.

Expected behavior: `BLOCK`

The skill must still collect all five intake answers before generating any
files. Pressure to skip intake does not override the Iron Law. If framework
is known but game target, language, or database need are missing, those must
still be asked explicitly.

Expected sibling skills:
- none

---

## cfx-client-server

### Trigger tests

#### CS-T01
Prompt:
> How do I send data from the client to the server and get a response back?

Expected skill: `cfx-client-server`

Expected output:
Working paired-event or callback pattern in Lua, with `local source = source`
captured on line 1 of the server handler.

Expected sibling skills:
- none

---

#### CS-T02
Prompt:
> Register a server-side net event in Lua that receives a player's action.

Expected skill: `cfx-client-server`

Expected output:
`RegisterNetEvent` + `AddEventHandler` with immediate source capture and a
server-side validation note.

Expected sibling skills:
- none

---

#### CS-T03
Prompt:
> Show me how exports work between two resources in FiveM.

Expected skill: `cfx-client-server`

Expected output:
`exports('FunctionName', ...)` definition and `exports['resource-name']:FunctionName()` call pattern.

Expected sibling skills:
- none

---

### Boundary tests

#### CS-B01
Prompt:
> Keep a player's job synchronized so all clients can read it at any time.

Must NOT primarily activate: `cfx-client-server`

Expected primary skill: `cfx-state-bags`

Reason: "synchronized so all clients can read it at any time" establishes
persistent replicated state, not a one-shot event.

Expected sibling skills:
- none

---

#### CS-B02
Prompt:
> What native do I use to get the player's position on the server?

Must NOT primarily activate: `cfx-client-server`

Expected primary skill: `cfx-natives`

Expected sibling skills:
- none

---

### Iron Law temptation

#### CS-I01
Prompt:
> I'll just read `source` from the global a few lines into the handler — it
> should still be the same player.

Expected behavior: `BLOCK`

The skill must flag this explicitly. After any yield or async gap `source`
can be a different player. The Iron Law is unconditional.

Expected sibling skills:
- none

---

## cfx-database

### Trigger tests

#### DB-T01
Prompt:
> Store persistent player money and inventory data in MySQL using oxmysql.

Expected skill: `cfx-database`

Expected output:
oxmysql query patterns using `@param` placeholders; schema design guidance;
server-side-only placement enforced.

Expected sibling skills:
- none

---

#### DB-T02
Prompt:
> Write an oxmysql query that loads a player's saved character data when they connect.

Expected skill: `cfx-database`

Expected output:
`MySQL.query.await` or callback variant with parameterized identifier lookup;
coroutine context noted if `.await` is used.

Expected sibling skills:
- none

---

#### DB-T03
Prompt:
> Help me design the schema for persistent FiveM player records.

Expected skill: `cfx-database`

Expected output:
`CREATE TABLE` DDL with `identifier` unique key, appropriate column types,
and index on foreign-key columns.

Expected sibling skills:
- none

---

### Boundary tests

#### DB-B01
Prompt:
> Explain how to synchronize temporary player state between the client and server.

Must NOT primarily activate: `cfx-database`

Expected primary skill: `cfx-state-bags`

Reason: "temporary" + "synchronize" points to runtime state replication, not
durable database storage.

Expected sibling skills:
- none

---

#### DB-B02
Prompt:
> How do I pass a value from the server to a client event?

Must NOT primarily activate: `cfx-database`

Expected primary skill: `cfx-client-server`

Expected sibling skills:
- none

---

### Iron Law temptation

#### DB-I01
Prompt:
> Build the query with string formatting — something like
> `'SELECT * FROM players WHERE id = ' .. playerId`. It's easier to read.

Expected behavior: `BLOCK`

String concatenation is SQL injection. The skill must reject this and
return a parameterized equivalent. The Iron Law is unconditional regardless
of "easier to read" justification.

Expected sibling skills:
- none

---

## cfx-framework-detect

### Trigger tests

#### FD-T01
Prompt:
> Which framework does this resource use? Here is the fxmanifest.lua.

Expected skill: `cfx-framework-detect`

Expected output:
Line 1: `Detected: <Framework>` or `Ambiguous — ask: <question>`.
Followed by the correct init snippet for the detected framework.

Expected sibling skills:
- none

---

#### FD-T02
Prompt:
> I'm on QBCore. Adapt the code you just generated to use the correct APIs.

Expected skill: `cfx-framework-detect`

Expected output:
`Detected: QBCore` (from explicit user statement). QBCore init snippet and
framework-specific API substitutions applied.

Expected sibling skills:
- none

---

#### FD-T03
Prompt:
> Detect the framework from these files and then give me the right player data call.

Expected skill: `cfx-framework-detect`

Expected output:
Detection via fxmanifest dependency check → grep for init pattern → result
stated on line 1 → correct `GetPlayerData` / `GetPlayer` call for that framework.

Expected sibling skills:
- none

---

### Boundary tests

#### FD-B01
Prompt:
> Write the RegisterNetEvent and TriggerServerEvent handlers for an ESX server.

Must NOT primarily activate: `cfx-framework-detect`

Expected primary skill: `cfx-client-server`

Note: ESX is contextual here, not the primary task. Framework detection is
incidental, not the reason the skill loaded.

Expected sibling skills:
- `cfx-framework-detect` — acceptable as a lightweight co-load only if
  framework-specific event naming or init patterns are needed to complete the answer

---

#### FD-B02
Prompt:
> Scaffold a new QBCore resource from scratch.

Must NOT primarily activate: `cfx-framework-detect`

Expected primary skill: `cfx-resource-scaffolding`

Expected sibling skills:
- `cfx-framework-detect` — acceptable as a co-load since framework identification
  feeds the scaffolding intake

---

### Iron Law temptation

#### FD-I01
Prompt:
> Just assume QBCore — it's the most common framework, probably fine.

Expected behavior: `BLOCK`

The skill must not assume. If framework cannot be determined from
fxmanifest.lua or init patterns, it must ask one clarifying question.
"Most common" is not a valid detection signal.

Expected sibling skills:
- none

---

## cfx-fxmanifest

### Trigger tests

#### FM-T01
Prompt:
> My Lua scripts aren't loading. Here's my fxmanifest.lua.

Expected skill: `cfx-fxmanifest`

Expected output:
Corrected manifest as a single `lua` code block. One-line explanation of
the mistake appended after the block.

Expected sibling skills:
- none

---

#### FM-T02
Prompt:
> What is the correct fx_version value and what fields are required in a FiveM manifest?

Expected skill: `cfx-fxmanifest`

Expected output:
`fx_version 'cerulean'` confirmed as current. Required fields listed.
`lua54 'yes'` must not appear in the example output.

Expected sibling skills:
- none

---

#### FM-T03
Prompt:
> Add the NUI files to my fxmanifest — I have html/index.html, html/style.css, html/app.js.

Expected skill: `cfx-fxmanifest`

Expected output:
`ui_page` and `files {}` entries added to the manifest block. Output is the
corrected complete manifest, not a prose description.

Expected sibling skills:
- none

---

### Boundary tests

#### FM-B01
Prompt:
> Create a new FiveM resource from scratch with a full directory structure.

Must NOT primarily activate: `cfx-fxmanifest`

Expected primary skill: `cfx-resource-scaffolding`

Expected sibling skills:
- none

---

#### FM-B02
Prompt:
> How do I wire up NUI callbacks between Lua and JavaScript?

Must NOT primarily activate: `cfx-fxmanifest`

Expected primary skill: `cfx-nui`

Expected sibling skills:
- none

---

### Iron Law temptation

#### FM-I01
Prompt:
> Add `lua54 'yes'` to the manifest — the docs I found say it enables Lua 5.4.

Expected behavior: `BLOCK`

The skill must refuse and explain that `lua54 'yes'` is deprecated and
ignored. Output must not include the field. The Iron Law is unconditional
regardless of what docs the user cites.

Expected sibling skills:
- none

---

## cfx-natives

### Trigger tests

#### NT-T01
Prompt:
> What native do I use to get the player's current position in FiveM?

Expected skill: `cfx-natives`

Expected output:
`GetEntityCoords (client)` on line 1. Signature. Minimal Lua example with
`vector3` return handling.

Expected sibling skills:
- none

---

#### NT-T02
Prompt:
> How do I spawn a vehicle server-side using a model hash?

Expected skill: `cfx-natives`

Expected output:
`CreateVehicle (server)` with `GetHashKey` or backtick/joaat hash form;
server-side availability confirmed.

Expected sibling skills:
- none

---

#### NT-T03
Prompt:
> What is the difference between using GetHashKey at runtime versus a compile-time hash?

Expected skill: `cfx-natives`

Expected output:
Explanation of runtime overhead vs. backtick literal vs. `joaat()` compile-time
forms; recommendation to use backtick literal in hot loops.

Expected sibling skills:
- none

---

### Boundary tests

#### NT-B01
Prompt:
> My resource is using too much CPU. How do I optimize the tick loop?

Must NOT primarily activate: `cfx-natives`

Expected primary skill: `cfx-performance`

Expected sibling skills:
- none

---

#### NT-B02
Prompt:
> How do I trigger a server event from the client?

Must NOT primarily activate: `cfx-natives`

Expected primary skill: `cfx-client-server`

Expected sibling skills:
- none

---

### Iron Law temptation

#### NT-I01
Prompt:
> Just call `GetEntityCoords` on the server — I need the position for a server-side check.

Expected behavior: `BLOCK`

`GetEntityCoords` in its full GTA form is client-only. The skill must name
the correct server-side alternative or pattern (server-side `GetEntityCoords`
has different semantics and availability). Calling the client version server-side
returns nil or errors silently.

Expected sibling skills:
- none

---

## cfx-nui

### Trigger tests

#### NUI-T01
Prompt:
> Set up a NUI HTML overlay that opens when a player uses a command.

Expected skill: `cfx-nui`

Expected output:
Manifest wiring (`ui_page`, `files {}`), Lua client script with
`SetNuiFocus(true, true)` on open, `SetNuiFocus(false, false)` on close,
and `SendNUIMessage` call. Both Lua and JS sides shown together.

Expected sibling skills:
- none

---

#### NUI-T02
Prompt:
> How do I send data from my Lua script to the in-game browser UI?

Expected skill: `cfx-nui`

Expected output:
`SendNUIMessage({ ... })` on the Lua side; `window.addEventListener('message', ...)`
on the JS side. Both blocks labelled and shown together.

Expected sibling skills:
- none

---

#### NUI-T03
Prompt:
> Register a NUI callback so the browser can tell Lua the user pressed submit.

Expected skill: `cfx-nui`

Expected output:
`RegisterNuiCallback('submit', function(data, cb) ... cb({ok=true}) end)` in
Lua; `fetch(https://${GetParentResourceName()}/submit, ...)` in JS. Both
sides shown together.

Expected sibling skills:
- none

---

### Boundary tests

#### NUI-B01
Prompt:
> Add the NUI files to my fxmanifest.

Must NOT primarily activate: `cfx-nui`

Expected primary skill: `cfx-fxmanifest`

Reason: The task is manifest editing, not NUI development patterns.

Expected sibling skills:
- none

---

#### NUI-B02
Prompt:
> Send data from the server to a client script so it can update a local variable.

Must NOT primarily activate: `cfx-nui`

Expected primary skill: `cfx-client-server`

Expected sibling skills:
- none

---

### Iron Law temptation

#### NUI-I01
Prompt:
> The UI hides itself when closed, so I don't need to call SetNuiFocus(false, false).

Expected behavior: `BLOCK`

Hiding the UI does not release focus. The skill must explain that mouse and
keyboard input remain captured by the invisible browser until
`SetNuiFocus(false, false)` is explicitly called.

Expected sibling skills:
- none

---

## cfx-performance

### Trigger tests

#### PF-T01
Prompt:
> My resource is showing 2ms in resmon. How do I optimize it?

Expected skill: `cfx-performance`

Expected output:
BAD pattern identified first (if present in prompt context), GOOD pattern
shown below it. resmon threshold table referenced. Dynamic Wait pattern
suggested if applicable.

Expected sibling skills:
- none

---

#### PF-T02
Prompt:
> Is it okay to use Wait(0) in a loop that checks if a player is near a location?

Expected skill: `cfx-performance`

Expected output:
BAD: Wait(0) for a proximity check. GOOD: dynamic Wait — large interval far,
small interval close. BEST: event-driven if proximity trigger is one-shot.

Expected sibling skills:
- none

---

#### PF-T03
Prompt:
> How do I reduce garbage collection pressure in C# tick handlers?

Expected skill: `cfx-performance`

Expected output:
C#-specific guidance: avoid heap allocations in Tick (no `new Vector3` per
frame), cache `Game.PlayerPed` outside tight loops, use `_tickCount % N`
pattern to throttle expensive checks.

Expected sibling skills:
- none

---

### Boundary tests

#### PF-B01
Prompt:
> My oxmysql queries are taking too long. How do I speed them up?

Must NOT primarily activate: `cfx-performance`

Expected primary skill: `cfx-database`

Reason: Database query performance is scoped to cfx-database (indexing,
query shape, prepared statements) not the general resource tick profiler.

Expected sibling skills:
- none

---

#### PF-B02
Prompt:
> I'm broadcasting a state bag update every frame. Is that a problem?

Must NOT primarily activate: `cfx-performance`

Expected primary skill: `cfx-state-bags`

Reason: Per-frame state bag updates are specifically called out in
cfx-state-bags as a design anti-pattern, not a generic performance concern.

Expected sibling skills:
- `cfx-performance` — acceptable as a co-load given the bandwidth impact framing

---

### Iron Law temptation

#### PF-I01
Prompt:
> I'll optimize it later. For now just use Wait(0) everywhere so it feels snappy.

Expected behavior: `BLOCK`

The skill must reject Wait(0) as a default. It must offer the correct Wait
value for the described use case and explain the compounding cost. "Optimize
later" is explicitly listed as a Red Flag rationalization.

Expected sibling skills:
- none

---

## cfx-state-bags

### Trigger tests

#### SB-T01
Prompt:
> Use Player.State to keep a player's job synchronized across all clients.

Expected skill: `cfx-state-bags`

Expected output:
`Player(source).state:set('job', value, true)` server-side;
`AddStateBagChangeHandler` for reactive client updates. Namespaced key enforced.

Expected sibling skills:
- none

---

#### SB-T02
Prompt:
> Attach fuel level to a vehicle entity so all clients can read it in real time.

Expected skill: `cfx-state-bags`

Expected output:
`Entity(vehicle).state:set('fuel', value, true)` with server-side update loop;
client-side `AddStateBagChangeHandler` for UI updates. Update frequency note
(not per-frame).

Expected sibling skills:
- none

---

#### SB-T03
Prompt:
> How does AddStateBagChangeHandler work and when should I use it?

Expected skill: `cfx-state-bags`

Expected output:
Handler signature explained (bagName, key, value, _reserved, replicated);
comparison of state bags vs events for when each is appropriate.

Expected sibling skills:
- none

---

### Boundary tests

#### SB-B01
Prompt:
> Save a player's job to MySQL so it persists after server restart.

Must NOT primarily activate: `cfx-state-bags`

Expected primary skill: `cfx-database`

Reason: "persist after server restart" establishes durable storage, not
runtime state replication.

Expected sibling skills:
- none

---

#### SB-B02
Prompt:
> Fire an event when a player enters a vehicle for the first time.

Must NOT primarily activate: `cfx-state-bags`

Expected primary skill: `cfx-client-server`

Reason: One-shot event on action; state bags are for persistent replicated
data, not one-shot action triggers.

Expected sibling skills:
- none

---

### Iron Law temptation

#### SB-I01
Prompt:
> Let the client set the player's money directly via a state bag — it's simpler
> than going through the server.

Expected behavior: `BLOCK`

The skill must reject this. Client-set state bags are fully controllable by
the client; any modded client sets money to an arbitrary value. Security-sensitive
state must only be set server-side.

Expected sibling skills:
- none

---

## cfx-txadmin

### Trigger tests

#### TX-T01
Prompt:
> Restart my resource using the txAdmin API after I edited the files.

Expected skill: `cfx-txadmin`

Expected output:
`txadmin_resource_control_tool(action="ensure", resource="<name>")`. Output
format: exact tool call + expected outcome in one line. For production server:
confirm resource name and action before executing.

Expected sibling skills:
- none

---

#### TX-T02
Prompt:
> Search for a player named "John" on the txAdmin panel and get their netid.

Expected skill: `cfx-txadmin`

Expected output:
`txadmin_player_search_tool(search_value="John", search_type="playerName")`.
Note that netid is session-scoped and must not be cached.

Expected sibling skills:
- none

---

#### TX-T03
Prompt:
> Kick a player from the server via txAdmin for being AFK.

Expected skill: `cfx-txadmin`

Expected output:
`txadmin_kick_player_tool(netid=<id>, reason="AFK")`. Confirm netid was
resolved fresh from a player search; warn that cached netids are invalid.

Expected sibling skills:
- none

---

### Boundary tests

#### TX-B01
Prompt:
> Write the server-side Lua code for a kick command inside my resource.

Must NOT primarily activate: `cfx-txadmin`

Expected primary skill: `cfx-client-server`

Reason: Writing resource code is cfx-client-server; txAdmin is for
operating the server panel via MCP tools, not authoring in-resource logic.

Expected sibling skills:
- none

---

#### TX-B02
Prompt:
> My resource is using too much CPU after a restart. How do I diagnose it?

Must NOT primarily activate: `cfx-txadmin`

Expected primary skill: `cfx-performance`

Reason: Performance diagnosis is cfx-performance; txAdmin is the restart
mechanism, not the profiling tool.

Expected sibling skills:
- none

---

### Iron Law temptation

#### TX-I01
Prompt:
> Use `start` to reload the resource — that's what I usually do after editing.

Expected behavior: `BLOCK`

The skill must redirect to `ensure`. `start` is a no-op on a running
resource. This is explicitly listed as the first Red Flag.

Expected sibling skills:
- none

---

## cfx-refresh

### Trigger tests

#### RF-T01
Prompt:
> Are my CFX skills up to date?

Expected skill: `cfx-refresh`

Expected output:
Reads `last-verified` and `volatility` from all 10 sibling SKILL.md files;
fetches oxmysql and txAdmin latest release tags; outputs ranked table or
all-OK compact message.

Expected sibling skills:
- none

---

#### RF-T02
Prompt:
> Check the freshness of the cfx developer tools skill pack.

Expected skill: `cfx-refresh`

Expected output:
Same as RF-T01.

Expected sibling skills:
- none

---

#### RF-T03
Prompt:
> What version is oxmysql at and does it match what's documented in the skills?

Expected skill: `cfx-refresh`

Expected output:
WebFetch of `https://api.github.com/repos/overextended/oxmysql/releases/latest`;
tag_name and published_at extracted; compared against `cfx-database`
`last-verified`; WATCH reported if release post-dates last-verified.

Expected sibling skills:
- none

---

### Boundary tests

#### RF-B01
Prompt:
> Write an oxmysql query for player inventory.

Must NOT primarily activate: `cfx-refresh`

Expected primary skill: `cfx-database`

Reason: Writing a query is cfx-database; cfx-refresh is not for authoring
FiveM code, only for auditing skill freshness.

Expected sibling skills:
- none

---

#### RF-B02
Prompt:
> Is txAdmin's HTTP API still accurate in the skills?

Must NOT primarily activate: `cfx-database` or `cfx-txadmin` as primaries.

Expected primary skill: `cfx-refresh`

Reason: This is a freshness/accuracy question about a skill, not a request
to use the txAdmin API.

Expected sibling skills:
- none

---

### Iron Law temptation

#### RF-I01
Prompt:
> The skills were just created this week, so they're definitely current.
> No need to check.

Expected behavior: `BLOCK`

The skill must not accept "just written" as a substitute for reading
`last-verified`. The Iron Law is unconditional: always read the field, never
assume. The skill must also still WebFetch upstream for high-volatility
dependencies regardless of how recent the skills appear.

Expected sibling skills:
- none

---

---

# Cross-skill Disambiguation Tests

These tests target the two highest-risk routing pairs where prompt phrasing
could legitimately match multiple skills. For ambiguous prompts, correct
behavior is to ask a clarifying question rather than force a guess.

---

## Database ↔ State Bags

### DISAMBIG-DBSB-01

Prompt:
> I need to store persistent player data.

Primary expected: `cfx-database`

Must not primarily route to: `cfx-state-bags`

Reason: "persistent" + "store" establishes durable cross-session storage.
State bags are runtime-only and cleared on disconnect.

Expected sibling skills:
- none

---

### DISAMBIG-DBSB-02

Prompt:
> Keep a player's current health synchronized so other clients can read it.

Primary expected: `cfx-state-bags`

Must not primarily route to: `cfx-database`

Reason: "current" + "synchronized" + "other clients can read it" establishes
runtime replication. Health is not a value you persist to a database on every
update — it's a live state bag candidate.

Expected sibling skills:
- none

---

### DISAMBIG-DBSB-03

Prompt:
> Keep player data available between client updates.

Expected: AMBIGUOUS

Required behavior: `AMBIG-OK`

The skill must ask one clarifying question before selecting a pattern:
> Does "available between updates" mean synchronized at runtime (state bags)
> or persisted across server restarts (database)?

Must not: Force the prompt into either bucket without asking.

Expected sibling skills:
- depends on clarification answer

---

## Client/Server ↔ Framework Detection

### DISAMBIG-CSFD-01

Prompt:
> Generate event code for my ESX server.

Primary expected: `cfx-client-server`

Conditional sibling: `cfx-framework-detect` only if generating framework-specific
event names or init patterns requires identifying ESX API behavior that cannot
be inferred from the stated "ESX" context alone.

Reason: The primary task is event architecture. ESX is a contextual constraint,
not an unknown requiring detection. The event pattern skill should handle this
with the ESX context already known.

---

### DISAMBIG-CSFD-02

Prompt:
> I have a resource but I don't know which framework it uses. Write the server
> event handler with the correct framework APIs.

Primary expected: `cfx-framework-detect` (detection phase first)

Sequential behavior: After detection resolves, the answer should use
`cfx-client-server` patterns adapted for the detected framework.

Required behavior: Detect before generating. Do not generate generic code
and tag it "adapt as needed" — that violates cfx-framework-detect's Iron Law.

Expected sibling skills:
- `cfx-client-server` — as the implementation substrate after detection completes

---

---

# How to Record Live Results

When running these tests in a live Claude Code session, create a results file:

```
tools/routing-results/YYYY-MM-DD-v1.1.0.md
```

For each test, record:

```
## DB-T01
Result: PASS
Skill activated: cfx-database
Sibling skills activated: none
Output shape: correct
Notes: —
```

A test run is complete when all 71 test cases have a recorded result.
Aggregate pass rate and any regressions go at the top of the results file.

---

*Matrix version 1.0.0 — committed before first live execution run.*
