---
name: cfx-performance
description: >-
  Identify and fix CFX-specific performance issues in FiveM/RedM Lua, JavaScript,
  and C# resources — Wait loops, thread optimization, resmon, and GC pressure.
  Use when the user asks about "high ms", "resource monitor", "Wait(0)",
  "optimize loop", "performance", "lag", "resmon", "frame rate", "tick handler",
  "slow resource", or "CPU spike". NOT for general code quality review (code-review);
  NOT for database query performance (cfx-database).
model: sonnet
allowed-tools: [Read, Grep, Glob, Edit, Write]
last-verified: 2026-10-03
volatility: medium
---

# CFX Performance Optimization

FiveM and RedM resources share a single game thread per resource. A poorly optimized resource degrades the server for all players — not just the one running the code.

## Iron Law

Never use `Wait(0)` in a loop unless the loop is explicitly drawing, checking player input, or doing per-frame work — because `Wait(0)` runs 60 times per second and burns CPU for every player connected, compounding with every other resource doing the same.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I need it responsive so I'll use Wait(0) everywhere" | Wait(0) × 60 players × N resources = CPU death; event-driven logic needs no tick at all | Use Wait(1000) or higher for polling; use events for reactions |
| "The resmon shows 0.1ms, that's fine" | 0.1ms × 60fps × 60 players = significant; idle resources should be near 0.0ms | Profile under load, not on an empty server |
| "I'll optimize later once it's working" | Performance regressions are exponentially harder to find after the codebase grows; the Wait(0) habit spreads | Set Wait values correctly from the first commit |
| "I'll cache the player ped globally once on resource start" | Ped handles are invalidated on respawn or character swap; a stale global handle crashes natives silently | Re-cache on `playerSpawned` and similar respawn events, not once at startup |
| "I'll spawn a new CreateThread per event callback for cleanliness" | Threads are lightweight in Lua but creating one per callback for short synchronous work adds scheduler overhead on busy servers | Execute simple synchronous logic directly in the event handler; only CreateThread when you genuinely need a loop or need to yield |

## Output format

Show the bad pattern first labeled `-- BAD:` then the fix labeled `-- GOOD:` or `-- BEST:`. No prose between them.

## Measuring performance

In the server console or F8:

```
resmon 1
```

Shows per-resource CPU time. Target:
- **Under 0.2ms idle** — well-optimized
- **0.2–1ms** — investigate; may be acceptable for active resources
- **Over 1ms** — must optimize

## Critical rules

### 1. Never use Wait(0) in loops unless necessary

`Wait(0)` runs every frame (~60 times per second). Only use it for:
- Drawing markers, text, or UI every frame
- Checking input (IsControlJustPressed) in a tight loop
- Per-frame game logic that genuinely requires it

```lua
-- BAD: polling a condition at 60fps
CreateThread(function()
    while true do
        Wait(0)
        if someCondition() then doThing() end
    end
end)

-- GOOD: poll at a reasonable interval
CreateThread(function()
    while true do
        Wait(500)
        if someCondition() then doThing() end
    end
end)

-- BEST: react to events instead of polling
AddEventHandler('myResource:conditionMet', function()
    doThing()
end)
```

### 2. Dynamic Wait — enter fast-loop only when needed

```lua
local inRange = false

CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local dist = #(coords - targetCoords)

        if dist < 10.0 then
            if not inRange then
                inRange = true
                -- show UI, start effects
            end
            Wait(0)  -- close range: per-frame updates acceptable
        else
            inRange = false
            Wait(2000)  -- far away: check every 2 seconds
        end
    end
end)
```

### 3. Use events instead of polling for reactions

```lua
-- BAD: polling every second to detect player entering vehicle
CreateThread(function()
    while true do
        Wait(1000)
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            -- ...
        end
    end
end)

-- GOOD: use CFX event
AddEventHandler('gameEventTriggered', function(name, args)
    if name == 'CEventNetworkPlayerEnteredVehicle' then
        -- ...
    end
end)
```

### 4. Cache repeated native calls

```lua
-- BAD: calling PlayerPedId() every iteration
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()  -- called 60x/sec unnecessarily
        DrawMarker(1, GetEntityCoords(ped), ...)
    end
end)

-- GOOD: cache the ped; re-fetch only on change
local cachedPed = PlayerPedId()
AddEventHandler('playerSpawned', function() cachedPed = PlayerPedId() end)

CreateThread(function()
    while true do
        Wait(0)
        DrawMarker(1, GetEntityCoords(cachedPed), ...)
    end
end)
```

### 5. Remove threads entirely when idle

```lua
local active = false

-- Only spin up the draw loop when the feature is active
local function startLoop()
    active = true
    CreateThread(function()
        while active do
            Wait(0)
            -- drawing logic
        end
    end)
end

local function stopLoop()
    active = false  -- thread exits naturally on next iteration
end
```

## JavaScript-specific tips

- Use `await Delay(ms)` instead of `Delay(0)` in `setTick` handlers
- Client-side JS does not have access to Node.js APIs — keep it lightweight
- Avoid heavy npm packages on the client side; they increase memory and parsing time
- `setTick` with no delay runs every frame — same rules as Wait(0) in Lua

```js
// BAD
setTick(async () => {
    await Delay(0);
    // runs 60x/sec
});

// GOOD
setTick(async () => {
    await Delay(500);
    // check twice per second
});
```

## C#-specific tips

- Always `await Delay(ms)` in `Tick` handlers — skipping it freezes the game thread
- Use `async`/`await` throughout; never block the main thread synchronously
- Minimize allocations in tick handlers — garbage collection pauses are visible as stutters
- Cache `Game.PlayerPed` outside tight loops; each access is a native call

```csharp
// BAD: allocation-heavy tick
private async Task OnTick()
{
    var position = Game.PlayerPed.Position;  // new Vector3 allocation every frame
    var nearbyVehicles = World.GetNearbyVehicles(position, 50f);  // heap allocation every frame
    await Delay(0);
}

// GOOD: reduce allocations
private Vector3 _lastPosition;
private int _tickCount = 0;

private async Task OnTick()
{
    _tickCount++;
    if (_tickCount % 30 == 0)  // run logic every 30 frames instead of every frame
    {
        _lastPosition = Game.PlayerPed.Position;
        // expensive checks here
    }
    await Delay(0);
}
```

## Summary: Wait value guidelines

| Situation | Recommended Wait |
|---|---|
| Drawing, input polling | `Wait(0)` |
| Distance checks, nearby detection | `Wait(500)` when far, `Wait(0)` when close |
| General game state polling | `Wait(1000)` |
| Server-side passive checks | `Wait(5000)` or event-driven |
| Truly idle resource | Thread exits; restart on event |
