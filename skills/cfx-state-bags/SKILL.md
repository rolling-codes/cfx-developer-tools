---
name: cfx-state-bags
description: >-
  Guide use of CFX State Bags for synchronized persistent data between client
  and server — Entity.State, Player.State, change handlers, security, and when
  to prefer state bags over events. Use when the user asks about "state bags",
  "Entity.State", "Player.State", "AddStateBagChangeHandler",
  "synchronize entity data", "player state", or "state bag". NOT for
  general client/server event patterns (cfx-client-server); NOT for performance
  tuning beyond state bag-specific notes (cfx-performance).
model: haiku
allowed-tools: [Read, Grep, Glob, Edit, Write]
last-verified: 2026-10-03
volatility: medium
---

# CFX State Bags

State Bags are a CFX mechanism for synchronized, persistent key-value data attached to players, entities, or the global state. They replace common patterns of repeated `TriggerClientEvent` broadcasts.

## Iron Law

Never trust client-replicated state bag values for authoritative game logic (money, permissions, health), because clients control their own replicated state and any player can set their own state to any value — validate server-side before acting.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll use client-set state for the player's money" | Any player can set their own state bags to arbitrary values; a modded client sets money to MAX_INT | Only server-set state is authoritative for security-sensitive values |
| "I'll update the state bag every frame to sync position" | State bags serialize and broadcast on every `.set()` — per-frame updates flood bandwidth for all clients | State bags are for data that changes infrequently (job, fuel, health status); use native position sync for fast-changing values |
| "I'll namespace my key as just `fuel` since it's obvious" | Key collisions across resources produce silent overwrites | Always namespace: `myResource:fuel`, `garage:fuel` — never bare keys |
| "I'll store the player's full inventory table in a state bag for easy client access" | State bags serialize and broadcast the entire value on every `.set()`; a large inventory table floods bandwidth for every connected player every update | Store large datasets server-side; send only what the client needs at the moment via a targeted event |
| "I'll use the shorthand `Entity(e).state.key = value` since it reads cleanly" | The property-assignment shorthand uses default replication and cannot be controlled; you may broadcast when you meant server-only | Use `:set(key, value, replicated)` explicitly so replication intent is always visible in the code |

## Output format

Lead with code. Append a one-line security note if the example involves client-set data or a security-sensitive key (money, permissions, job). Skip the note for purely cosmetic state (blip colour, UI state).

## Three types of State Bags

| Type | Access | Notes |
|---|---|---|
| `Player.State[playerId]` | Server and client | Player-attached; persists until the player disconnects |
| `Entity(handle).state` | Server and client | Entity-attached; destroyed with the entity |
| `GlobalState` | Server and client | Server-wide; all clients and server share it |

## Setting and reading state

```lua
-- Server: set player state
Player(source).state:set('job', 'police', true)  -- true = replicate to all clients

-- Client: read player state (own player)
local job = Player(PlayerId()).state.job

-- Server: set entity state
Entity(vehicle).state:set('fuel', 100.0, true)

-- Client: read entity state
local fuel = Entity(vehicle).state.fuel

-- GlobalState (server-set, all can read)
GlobalState:set('serverTime', os.time(), true)
local serverTime = GlobalState.serverTime
```

The third argument to `:set()` is `replicated` — `true` means all clients receive the update; `false` means only the server sees it.

## Replication rules

| Set from | replicated=true | replicated=false |
|---|---|---|
| Server | All clients receive the value | Server-only; clients see nil |
| Client | Other clients receive the value | Only the owning client sees it |

Client-set state with `replicated=true` is visible to other clients but **never authoritative** — the server should validate before acting on it.

## Change handlers

```lua
-- Server: react to any state bag key change globally
AddStateBagChangeHandler('job', nil, function(bagName, key, value, _reserved, replicated)
    -- bagName: e.g. 'player:5'
    -- key: 'job'
    -- value: new value
    -- replicated: true if set by a client
    local playerId = tonumber(bagName:match('player:(%d+)'))
    -- update server-side data
end)

-- Client: react to a specific player's state change
AddStateBagChangeHandler('job', 'player:' .. GetPlayerServerId(PlayerId()), function(_, _, value)
    if value then
        -- update local UI, blips, etc.
    end
end)
```

## JavaScript patterns

```js
// Set from server
Player(source).state.set('job', 'police', true);

// Read from client
const job = Player(PlayerId()).state.job;

// Change handler
AddStateBagChangeHandler('job', null, (bagName, key, value) => {
    // react to change
});
```

## When to use State Bags vs Events

| Use State Bags when | Use Events when |
|---|---|
| Data persists and multiple clients need to read it on join | A one-shot action (trigger animation, play sound) |
| Newly connecting clients need the current value | Data is only relevant for a brief moment |
| Multiple systems react to the same changing value | You need request/response (use cfx-client-server callback pattern) |
| Entity properties (fuel, health, ownership) | Player actions (press key, enter vehicle for the first time) |

## Security

- Server-set state is authoritative — clients cannot override it
- Client-set state is only visible to the owning client unless explicitly replicated
- Never trust client-replicated state for security-sensitive logic
- Validate on the server before acting on any client-set state change:

```lua
AddStateBagChangeHandler('customData', nil, function(bagName, key, value, _reserved, replicated)
    if replicated then
        -- value came from a client — validate before trusting
        local entity = GetEntityFromStateBagName(bagName)
        if not isEntityOwnedByTrustedSource(entity) then
            return  -- reject silently
        end
    end
    -- safe to act on
end)
```

## Best practices

1. **Namespace keys** — `resourceName:key` avoids collisions (`garage:fuel`, not `fuel`)
2. **Keep values shallow** — state bags serialize the entire value on every `.set()`; avoid deeply nested tables
3. **Don't update frequently** — state bags are not designed for per-frame updates; use them for data that changes infrequently
4. **Clean up explicitly if needed** — state bags are auto-cleared when the entity is deleted; manually clear custom state if your resource tracks it elsewhere
5. **Use `:set()` for control** — the shorthand `Entity(e).state.key = value` always uses default replication; use `:set(key, value, replicated)` when you need explicit control

## Common patterns

### Vehicle fuel system

```lua
-- Server: initialize fuel on vehicle spawn
local vehicle = CreateVehicle(model, x, y, z, heading, true, true)
Entity(vehicle).state:set('fuel', 100.0, true)

-- Server: consume fuel periodically (scheduled update, not per-frame)
CreateThread(function()
    while DoesEntityExist(vehicle) do
        Wait(10000)
        local current = Entity(vehicle).state.fuel
        if current > 0 then
            Entity(vehicle).state:set('fuel', math.max(0, current - 1.0), true)
        end
    end
end)

-- Client: react to fuel change and update UI
AddStateBagChangeHandler('fuel', 'entity:' .. NetworkGetNetworkIdFromEntity(vehicle), function(_, _, value)
    updateFuelGauge(value)
end)
```

### Player job sync

```lua
-- Server: set job on player connect or job change
Player(source).state:set('job', playerJob, true)

-- Client: react to job change on any player (for blips, markers)
AddStateBagChangeHandler('job', nil, function(bagName, _, value)
    local playerServerId = tonumber(bagName:match('player:(%d+)'))
    if playerServerId then
        updateJobBlip(playerServerId, value)
    end
end)
```
