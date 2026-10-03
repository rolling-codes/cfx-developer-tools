---
name: cfx-framework-detect
description: >-
  Detect the active FiveM/RedM framework (ESX, QBCore, Qbox, ox_core, VORP,
  RSG, or standalone) from a resource's fxmanifest.lua and Lua files, then
  adapt generated code to use the correct APIs. Use when the user says "which
  framework is this", "I'm using QBCore", "adapt for ESX", "detect framework",
  or when generating code that must match a project's existing framework patterns.
  NOT for writing framework feature code after detection (cfx-client-server);
  NOT for full resource scaffolding (cfx-resource-scaffolding).
model: sonnet
allowed-tools: [Read, Grep, Glob]
last-verified: 2026-10-03
volatility: high
---

# CFX Framework Detection

Identify which RP framework a resource uses so generated code targets the correct APIs — wrong framework APIs produce runtime errors that are invisible until players hit the feature.

## Iron Law

Always detect before generating framework-specific code, because ESX and QBCore have different function signatures, initialization patterns, and event names — mixing them silently fails at runtime, not at code-review time.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll assume QBCore since it's most common" | Servers run a mix; generating QBCore code for an ESX server causes cryptic nil errors at runtime | Read fxmanifest.lua and grep for init patterns; ask if still ambiguous |
| "The framework doesn't matter for this feature" | Framework APIs (player data, notifications, items) differ in name, argument order, and return shape | Always detect; even small helpers often call ESX.GetPlayerData vs QBCore.Functions.GetPlayerData |
| "Multiple frameworks detected — I'll use both" | A single resource must depend on exactly one framework | Warn the user and ask which one to target |
| "Qbox is basically QBCore so I'll use the same patterns" | Qbox diverged significantly — it uses ox_lib for notifications, menus, and callbacks rather than QBCore's built-in helpers; mixing them causes nil errors | Use Qbox-specific patterns; if the server uses ox_lib, use `lib.notify` and `lib.callback`, not `QBCore.Functions.Notify` |
| "I'll check a ConVar or global variable to detect the framework" | ConVars are not reliable framework indicators and can be spoofed; global variable presence depends on script load order | Read fxmanifest.lua `dependency` lines first — they are the authoritative declaration |

## Output format

Line 1: `Detected: <Framework>` (or `Ambiguous — ask: <one question>`). Then the correct init snippet for the detected framework. Nothing else until the user confirms or redirects.

## Detection logic — run in order

### Step 1: Check fxmanifest.lua `dependency`

```lua
dependency 'es_extended'    --> ESX
dependency 'qb-core'        --> QBCore
dependency 'qbx_core'       --> Qbox
dependency 'ox_core'        --> ox_core
dependency 'vorp_core'      --> VORP (RedM)
dependency 'rsg-core'       --> RSG (RedM)
```

### Step 2: Search server scripts for GetSharedObject / init calls

```lua
exports['es_extended']:getSharedObject()   --> ESX
exports['qb-core']:GetCoreObject()         --> QBCore
exports['qbx_core']                        --> Qbox
require '@ox_core.lib.init'                --> ox_core
exports.vorp_core:GetCore()                --> VORP (RedM)
exports['rsg-core']:GetCoreObject()        --> RSG (RedM)
```

### Step 3: No match → standalone

If none of the above patterns are found, assume **standalone** (no framework dependency).

## Framework initialization patterns

### ESX

```lua
-- Recommended (modern ESX)
ESX = exports['es_extended']:getSharedObject()

-- Legacy (older ESX versions, still works)
ESX = nil
TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
```

Common ESX patterns:

```lua
-- Get player data
local xPlayer = ESX.GetPlayerData()          -- client
local xPlayer = ESX.GetPlayerFromId(source)  -- server

-- Show notification
ESX.ShowNotification('Message here')

-- Register a usable item (server)
ESX.RegisterUsableItem('itemname', function(source)
    local xPlayer = ESX.GetPlayerFromId(source)
    -- handle use
end)
```

### QBCore

```lua
QBCore = exports['qb-core']:GetCoreObject()
```

Common QBCore patterns:

```lua
-- Get player data
local PlayerData = QBCore.Functions.GetPlayerData()       -- client
local Player = QBCore.Functions.GetPlayer(source)          -- server

-- Show notification
QBCore.Functions.Notify('Message here', 'success')

-- Register usable item (server)
QBCore.Functions.CreateUseableItem('itemname', function(source, item)
    local Player = QBCore.Functions.GetPlayer(source)
    -- handle use
end)
```

### Qbox

```lua
local QBX = exports.qbx_core
```

Qbox diverged from QBCore. Modern Qbox resources use **ox_lib** for notifications, menus, and callbacks rather than QBCore's built-in helpers:

```lua
-- Notification (Qbox/ox_lib style — not QBCore.Functions.Notify)
lib.notify({ title = 'Success', description = 'Item purchased', type = 'success' })

-- Player data (client)
local PlayerData = QBX:GetPlayerData()

-- Player data (server)
local Player = QBX:GetPlayer(source)
```

Servers running Qbox typically have `ox_lib` as a dependency — check fxmanifest.lua for `dependency 'ox_lib'`.

### ox_core

```lua
-- Server script: load the ox_core library
require '@ox_core.lib.init'
```

ox_core uses a Lua module system, not a shared-object export. Getting player data:

```lua
-- Server: get player object
local player = Ox.GetPlayer(source)
if player then
    local name = player.name
    local group = player.group  -- replaces job/gang pattern
end

-- Client: your own server ID
local serverId = cache.serverId  -- from ox_lib cache
```

ox_core's `group` system replaces the ESX/QBCore job concept. Generating code for ox_core without this distinction produces broken logic.

### VORP (RedM)

```lua
local VORPcore = exports.vorp_core:GetCore()
```

Common patterns:

```lua
local User = VORPcore.GetUser(source)
local Character = User.getUsedCharacter
```

### RSG (RedM)

```lua
RSGCore = exports['rsg-core']:GetCoreObject()
```

Common patterns:

```lua
local PlayerData = RSGCore.Functions.GetPlayerData()          -- client
local Player = RSGCore.Functions.GetPlayer(source)            -- server
```

## Adapting generated code

When generating code for a detected framework:

1. **Add the correct dependency** in fxmanifest.lua
2. **Use the correct initialization** at the top of client and server scripts
3. **Use framework-specific APIs** for player data, notifications, items, and callbacks
4. **Match the project's existing patterns** — if the codebase uses ESX legacy style, do not switch to modern style mid-resource

## Multiple frameworks detected

This should not happen in a well-structured resource. If it does, warn the user and ask which framework they intend to use. A single resource should only depend on one framework.
