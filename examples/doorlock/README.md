# doorlock

Server-authoritative door lock system using GlobalState bags for state replication.

## Patterns demonstrated

- `GlobalState:set(key, value, replicate)` — server writes, all clients read via `AddStateBagChangeHandler`
- Server-side range check — client sends a toggle request; server validates proximity before acting
- Anti-spam cooldown — one toggle per second per player, enforced server-side
- `RegisterKeyMapping` — player-remappable key binding

## Setup

1. Copy the `doorlock/` folder to your resources directory.
2. Adjust `Config.Doors` in `config.lua` to match your map's door props and coords.
3. `ensure doorlock` in your server config.

## Extending

To apply a visual lock state, replace the `print` call in `client/main.lua`'s `AddStateBagChangeHandler` with:
- `DoorSystemSetDoorState(doorHash, coordsX, coordsY, coordsZ, locked ? 1 : 0)` for map doors
- Freeze/unfreeze the entity for prop-based doors

## Notes

- Door state survives player reconnects — GlobalState persists for the resource lifetime.
- This example does not include permission checks (job, item, etc.). Add those in `server/main.lua` before the toggle.
