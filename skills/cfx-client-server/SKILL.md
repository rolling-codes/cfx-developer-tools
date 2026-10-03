---
name: cfx-client-server
description: >-
  Provide correct CFX client/server scripting patterns for Lua, JavaScript, and
  C# — events, exports, callbacks, routing buckets, and vector types. Use when
  the user asks about "RegisterNetEvent", "TriggerServerEvent", "TriggerClientEvent",
  "how do I send data from client to server", "client event", "server event",
  "exports", "callback pattern", "routing bucket", or "network event". NOT for
  state bag patterns (cfx-state-bags); NOT for native function lookup (cfx-natives);
  NOT for manifest file edits (cfx-fxmanifest); NOT for database queries (cfx-database).
model: sonnet
allowed-tools: [Read, Grep, Glob, Edit, Write]
last-verified: 2026-10-03
volatility: medium
---

# CFX Client-Server Patterns

FiveM and RedM resources run code on two sides: the **client** (each player's game) and the **server** (the central authority). Communication between them uses network events.

## Iron Law

Always capture `source` as a local variable on the first line of every server event handler, because the global `source` can change between yields — using it after an `await` or a `Wait()` reads a different player's source and creates subtle security holes and logic bugs.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll read `source` from the global when I need it" | The global changes on any yield or async gap; a player could disconnect and their source reused | `local src = source` on line 1 of every server event handler, every time |
| "State bags and events do the same thing, I'll use events for everything" | Events fire once and don't persist; state bags replicate and persist — wrong tool for player status/entity properties | Use events for one-shot actions; use cfx-state-bags for persistent sync |
| "I'll skip RegisterNetEvent since it's optional in newer CFX" | Without RegisterNetEvent, the handler silently refuses networked events | Always call RegisterNetEvent before AddEventHandler for any networked event |
| "I'll broadcast with -1 since it's simpler than tracking target players" | `TriggerClientEvent(event, -1, ...)` sends to every connected player; bandwidth scales with player count and payload size | Pass the specific `source` or build a targeted list; only use -1 for true server-wide announcements |
| "I'll use a short event name like `getData` since it's obvious from context" | Short names collide silently when two resources both register `getData`; the last-registered handler wins | Always namespace: `resourceName:getData`, `myShop:purchaseItem` — never bare names |
| "I can skip server-side validation since the client already checked the value" | Clients are untrusted; a modded client sends any value regardless of what the UI validates | Validate every value on the server before acting — treat all client-sent data as hostile input |

## Output format

Code first. Annotate security-sensitive lines (`local source = source`, input validation points) with a brief inline comment so the user knows why those lines matter.

## Lua patterns

### Thread with proper Wait

```lua
CreateThread(function()
    while true do
        Wait(1000)  -- NEVER use Wait(0) unless drawing or checking input
        -- your logic here
    end
end)
```

### Registering a client event

```lua
RegisterNetEvent('myResource:clientEvent', function(data)
    -- handle event from server
end)
```

`RegisterNetEvent` must be called before the handler can receive network events.

### Triggering a server event from client

```lua
TriggerServerEvent('myResource:serverEvent', someData)
```

### Registering a server event

```lua
RegisterNetEvent('myResource:serverEvent', function(data)
    local source = source  -- capture immediately — global can change between yields
    -- validate source, then handle event
end)
```

### Exports

```lua
exports('MyFunction', function(param)
    return result
end)
```

Other resources call this with `exports['resource-name']:MyFunction(param)`.

### Callbacks (request/response pattern)

For request/response patterns, use a callback library (ox_lib recommended) or implement with paired events:

```lua
-- Client: request data
TriggerServerEvent('myResource:getData', requestId)

-- Client: receive response
RegisterNetEvent('myResource:dataResponse', function(requestId, data)
    -- handle response
end)

-- Server: handle request and respond
RegisterNetEvent('myResource:getData', function(requestId)
    local source = source
    local data = getDataForPlayer(source)
    TriggerClientEvent('myResource:dataResponse', source, requestId, data)
end)
```

## JavaScript patterns

### Registering a client event

```js
onNet('myResource:clientEvent', (data) => {
    // handle event from server
});
```

### Triggering a server event from client

```js
emitNet('myResource:serverEvent', someData);
```

### Registering a server event

```js
onNet('myResource:serverEvent', (data) => {
    const src = source;  // capture immediately
    // validate and handle
});
```

### Exports

```js
exports('MyFunction', (param) => {
    return result;
});
```

## C# patterns

### Registering a client event

```csharp
EventHandlers["myResource:clientEvent"] += new Action<dynamic>(OnClientEvent);

private void OnClientEvent(dynamic data)
{
    // handle event from server
}
```

### Triggering a server event from client

```csharp
TriggerServerEvent("myResource:serverEvent", someData);
```

### Registering a server event

```csharp
EventHandlers["myResource:serverEvent"] += new Action<Player, dynamic>(OnServerEvent);

private void OnServerEvent([FromSource] Player player, dynamic data)
{
    // player.Handle is the source — already captured safely by the attribute
}
```

## Event naming conventions

- Use `resourceName:eventName` format: `myShop:purchaseItem`
- Use camelCase for event names
- Keep names descriptive enough to know which resource owns them
- Never use generic names like `event1` or `getData` (collide across resources)

## Vector types in client-server code

Vectors passed over network events are serialized — pass as tables, not native vector types:

```lua
-- WRONG: vector3 may not deserialize correctly on the other side
TriggerServerEvent('myResource:setPos', GetEntityCoords(ped))

-- CORRECT: pass as table
local coords = GetEntityCoords(ped)
TriggerServerEvent('myResource:setPos', { x = coords.x, y = coords.y, z = coords.z })
```

## Routing buckets (instances)

Routing buckets separate players into isolated game instances on the same server:

```lua
-- Server: put player in bucket 1
SetPlayerRoutingBucket(playerId, 1)

-- Server: enable NPC population in bucket 1 (disabled by default)
SetRoutingBucketPopulationEnabled(1, true)

-- Server: return player to default bucket
SetPlayerRoutingBucket(playerId, 0)
```

Players in different buckets cannot see each other's entities.

## Key rules

- `source` is only valid on the server side; it is the netId of the player who triggered the event
- Never trust data sent by a client — always validate on the server before acting
- `TriggerClientEvent(eventName, -1, ...)` broadcasts to all players; use sparingly
- RegisterNetEvent is required server-side too, not only client-side
- For persistent data sync between sides, prefer State Bags (cfx-state-bags) over polling events
