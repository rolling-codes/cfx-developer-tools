---
name: cfx-natives
description: >-
  Look up and correctly use FiveM and RedM native functions — calling
  conventions, client vs server vs shared availability, commonly used natives,
  and hash optimization. Use when the user asks "what native does X",
  "how to use GetPlayerPed", "GetEntityCoords", "which native for Y",
  "cfx native", "native function", or names a specific native function.
  NOT for general client/server event patterns (cfx-client-server);
  NOT for performance analysis beyond native-specific notes (cfx-performance).
model: haiku
allowed-tools: [Read, Grep, Glob, WebFetch]
last-verified: 2026-10-03
volatility: low
---

# CFX Native Function Reference

Native functions are low-level game APIs exposed by FiveM and RedM. Misusing them — wrong context, wrong arguments, deprecated hash — causes silent failures or crashes.

## Iron Law

Always verify whether a native is client-only, server-only, or shared before using it, because calling a client native from a server script (or vice versa) silently returns nil or errors without a meaningful stack trace.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll call GetEntityCoords on the server" | GetEntityCoords is client-only; the server uses GetEntityCoords differently or uses position state | Check the native reference; server-side equivalent is available for some natives but not all |
| "I'll use the string native name in GetHashKey at runtime" | Runtime GetHashKey adds a small per-call overhead; for frequently-called natives use the integer hash literal | Use `joaat('model_name')` at compile time or cache the hash result |
| "The native documentation looks outdated but the name is the same" | Native signatures change between GTA/GTAV/GTAVMP/RDR3; FiveM may alias or wrap some — always verify on nativedb.dotindustries.dev | Check the CFX native database for the exact current signature |
| "I'll call Entity(handle) on the server without checking if it exists" | Invalid entity handles passed to natives cause crashes or return garbage values with no meaningful error | Always guard with `DoesEntityExist(handle)` before calling entity natives server-side |
| "This native works in FiveM so it'll work in RedM too" | Many GTA-V game natives are stubs or no-ops in RedM; behaviour differences are silently swallowed | Test on the target game; check the RDR3 native database separately for RedM resources |

## Output format

`NativeName (client | server | shared)` on line 1. Signature on line 2. Then a minimal working Lua example. Add a one-line warning only if the native has a common misuse pattern directly relevant to the request.

## Reference

The authoritative native reference for FiveM and RedM:

- **FiveM**: https://nativedb.dotindustries.dev/natives (CFX fork with FiveM-specific annotations)
- **RedM**: https://nativedb.dotindustries.dev/rdr3 (RDR3 natives)
- **Backup**: https://docs.fivem.net/natives/

## Calling conventions

### Lua

```lua
-- Direct call (recommended)
local ped = PlayerPedId()
local coords = GetEntityCoords(ped)

-- With multiple return values
local x, y, z = table.unpack(GetEntityCoords(ped))
-- or destructure the vector3:
local pos = GetEntityCoords(ped)
print(pos.x, pos.y, pos.z)
```

### JavaScript

```js
// Natives are global functions
const ped = PlayerPedId();
const coords = GetEntityCoords(ped);
```

### C#

```csharp
using CitizenFX.Core.Native;

// via API class
var ped = Game.PlayerPed;
var coords = API.GetEntityCoords(ped.Handle, false);
```

## Client vs server vs shared

| Context | Available natives |
|---|---|
| **Client** | All GTA/RDR3 game natives + CFX client natives |
| **Server** | CFX server natives only (player management, entity spawning, routing buckets) |
| **Shared** | A small set callable from both sides |

Common client-only natives (NOT available server-side):

- `GetEntityCoords`, `SetEntityCoords` (client has the full GTA version)
- `PlayerPedId`, `PlayerId`
- All drawing/rendering natives (`DrawRect`, `DrawText3d`, etc.)
- `SetEntityAlpha`, `SetEntityVisible`

Common server-side natives:

- `GetEntityCoords(entity)` — server version with different semantics
- `GetPlayerPed(playerId)` — get the ped entity handle for a player
- `CreateVehicle`, `CreatePed`, `CreateObject` — spawn entities server-side
- `SetPlayerRoutingBucket`, `GetPlayerRoutingBucket`
- `GetPlayerName`, `GetPlayerIdentifiers`, `DropPlayer`

## Commonly used client natives

```lua
-- Ped
local ped = PlayerPedId()
local vehicle = GetVehiclePedIsIn(ped, false)  -- false = current vehicle
local isInVehicle = IsPedInAnyVehicle(ped, false)

-- Coords
local coords = GetEntityCoords(ped)
local heading = GetEntityHeading(ped)

-- Distance check
local targetCoords = vector3(100.0, 200.0, 30.0)
local dist = #(coords - targetCoords)
if dist < 5.0 then
    -- within 5 units
end

-- Markers
DrawMarker(1, x, y, z, 0, 0, 0, 0, 0, 0, 0.5, 0.5, 0.5, 255, 0, 0, 200, false, true, 2, false, false, false, false)

-- Blips
local blip = AddBlipForCoord(x, y, z)
SetBlipSprite(blip, 1)
SetBlipColour(blip, 3)
SetBlipAsShortRange(blip, true)
BeginTextCommandSetBlipName("STRING")
AddTextComponentSubstringPlayerName("My Blip")
EndTextCommandSetBlipName(blip)
```

## Commonly used server natives

```lua
-- Player info
local name = GetPlayerName(source)
local identifiers = GetPlayerIdentifiers(source)

-- Get ped
local ped = GetPlayerPed(source)
local coords = GetEntityCoords(ped)

-- Spawn vehicle
local vehicle = CreateVehicle(GetHashKey('adder'), x, y, z, heading, true, true)

-- Kick
DropPlayer(source, 'Kicked: reason')

-- Routing
SetPlayerRoutingBucket(source, bucketId)
```

## Hash optimization

For models or entities referenced in hot loops, pre-hash:

```lua
-- Avoid (hashes string every call)
RequestModel(GetHashKey('adder'))

-- Prefer (hash is a compile-time integer literal)
RequestModel(0x6ABDF65D)  -- `adder` hash

-- Or cache once
local ADDER_HASH = GetHashKey('adder')
RequestModel(ADDER_HASH)
```

FiveM's Lua runtime supports two compile-time hash forms:

```lua
-- Backtick literal (preferred — Lua parser converts to integer at parse time)
local model = `adder`
RequestModel(`adder`)

-- joaat() explicit call (same result; useful when the string is in a variable)
local ADDER_HASH = joaat('adder')
RequestModel(ADDER_HASH)
```

## Tips

- `GetEntityCoords` returns a `vector3` in Lua; use `.x`, `.y`, `.z` fields or `table.unpack()`
- Distance between two vector3s: `#(v1 - v2)` (Lua vector magnitude operator)
- Natives that take entity handles work with both ped and vehicle handles — verify the entity type
- Server-spawned entities are not always immediately visible to clients; wait for entity replication
- Some natives are GTA-only and silently do nothing in RedM — test on the target game
