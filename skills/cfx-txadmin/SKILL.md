---
name: cfx-txadmin
description: >-
  Control a FiveM/RedM server via the txAdmin API — restart resources, search
  players, and kick players using MCP tools. Use when the user mentions
  "txAdmin", "restart resource via txAdmin", "kick player via txAdmin",
  "txadmin_server_control_tool", "txAdmin API", "txAdmin panel", or
  "txAdmin console". NOT for writing FiveM resource code (cfx-client-server);
  NOT for general FiveM server administration or SSH/console access unrelated
  to the txAdmin HTTP API.
model: sonnet
allowed-tools: [Read, Grep, Glob]
last-verified: 2026-10-03
volatility: high
---

# txAdmin Integration

txAdmin is the FiveM/RedM server management panel. This skill covers the txAdmin MCP tools for controlling a running server — no SSH or console access needed.

## Iron Law

Always confirm the `action` value before calling `txadmin_resource_control_tool` on a production server, because `stop` and `restart` immediately disconnect players from that resource — there is no undo, and a wrong resource name does not error, it just silently does nothing.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll use `start` to refresh the resource after editing" | `start` only works on stopped resources; if the resource is already running, it does nothing | Use `ensure` — it starts if stopped, restarts if running |
| "I'll hardcode the txAdmin URL and credentials in the script" | Credentials in source code are a security risk | Store txAdmin URL, username, and password as environment variables or in a gitignored config |
| "I'll try to restart `runcode` since it's a useful debugging resource" | txAdmin blocks start/restart of `runcode` for security | Use other methods for live code execution; `runcode` intentionally cannot be restarted via txAdmin API |
| "I'll use `restart` instead of `ensure` for reliability" | `restart` fails silently if the resource is not currently running; `ensure` handles both running and stopped states correctly | Default to `ensure` for all post-edit refreshes; only use `restart` when you explicitly need to avoid starting a stopped resource |
| "I'll cache the player's netid for later use" | `netid` is session-scoped and changes every time a player reconnects; a cached netid from even minutes ago may belong to a different player | Always resolve the netid fresh from a player search immediately before using it |

## Output format

Output the exact tool call(s). State the expected outcome in one line. For `stop` or `restart` actions targeting a production server: confirm the resource name and action with the user before executing.

## Authentication

txAdmin uses session-based auth with CSRF protection. The MCP tools handle authentication automatically, but they need credentials configured:

| Variable | Description |
|---|---|
| `txadmin_url` | Full URL to the txAdmin panel, e.g. `http://localhost:40120` |
| `txadmin_username` | txAdmin admin username |
| `txadmin_password` | txAdmin admin password |

The MCP tools read these from environment variables. Set them in your `.env` or shell before using the tools.

## Usage

### Resource control

```
txadmin_resource_control_tool(action="ensure", resource="my-resource")
```

Valid actions:

| Action | Behavior |
|---|---|
| `start` | Starts a stopped resource; no-op if already running |
| `stop` | Stops a running resource |
| `restart` | Restarts a running resource |
| `ensure` | Starts if stopped, restarts if running — **use this for post-edit refreshes** |

txAdmin blocks starting or restarting the `runcode` resource for security.

### Player search

```
txadmin_player_search_tool(search_value="John", search_type="playerName")
txadmin_player_search_tool(filters="isOnline,isAdmin")
```

`search_type` options:
- `playerName` — search by player name
- `playerNotes` — search by admin notes attached to the player
- `playerIds` — search by identifier (Steam ID, license, etc.)

`filters` options (comma-separated): `isAdmin`, `isOnline`, `isWhitelisted`, `hasNote`

Results include both online players and the player database. The server caps results at 100.

### Kick a player

```
txadmin_kick_player_tool(netid=42, reason="AFK too long")
```

`netid` is the player's current net ID (not database ID). Get it from player search results.

## Gotchas

- `ensure` is almost always the right action after editing resource files
- `start` does nothing on an already-running resource — use `restart` or `ensure`
- `restart` briefly disconnects players from the resource; active players may notice an interruption
- Player `netid` changes every time a player reconnects; don't cache netids across sessions
- The player search cap is 100 results — narrow searches with `search_value` or `filters` for large servers
- The txAdmin API requires an active session; if credentials are wrong, tool calls fail with an auth error

## Related skills

- For writing or editing the FiveM resource code being managed: `cfx-client-server`
- For scaffolding a new resource to deploy via txAdmin: `cfx-resource-scaffolding`
- For performance issues found after restarting a resource: `cfx-performance`
