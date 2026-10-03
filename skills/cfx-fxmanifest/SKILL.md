---
name: cfx-fxmanifest
description: >-
  Expert guidance on writing and editing fxmanifest.lua resource manifests —
  required fields, script declarations, dependencies, NUI setup, data files,
  C#/JS specifics, escrow, and common mistakes. Use when the user asks about
  "fxmanifest", "fx_version", "manifest", "script not loading", "resource
  manifest", "games { }", "lua54", "ui_page", "data_file", or "provide/replace".
  NOT for full resource scaffolding from scratch (cfx-resource-scaffolding);
  NOT for NUI UI design beyond manifest wiring (cfx-nui).
model: haiku
allowed-tools: [Read, Grep, Glob, Edit, Write]
last-verified: 2026-10-03
volatility: low
---

# fxmanifest.lua Expert

The resource manifest (`fxmanifest.lua`) defines metadata, dependencies, and file includes for every CFX resource. It replaced the deprecated `__resource.lua` format.

## Iron Law

Never add `lua54 'yes'` to any manifest, because it is deprecated, ignored by the runtime, and signals to experienced developers that the author is following outdated documentation — all scripts already run on Lua 5.4 by default.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll add `lua54 'yes'` since Lua 5.4 is newer" | Deprecated; ignored; confuses LSP tooling | Omit it entirely |
| "I'll use `__resource.lua` since I have an example that uses it" | `__resource.lua` is the legacy format, replaced by `fxmanifest.lua` | Always use `fxmanifest.lua` |
| "The script glob `*.lua` will catch everything" | Globs don't recurse into subdirectories without `**`; `client/*.lua` misses `client/utils/*.lua` | Use explicit paths or the correct glob depth for the directory structure |
| "I'll add everything to `shared_scripts` for convenience since both sides can use it" | Scripts in `shared_scripts` run on both client AND server, doubling memory and exposing server-only logic (credentials, database calls) to clients | Put server-only logic in `server_scripts`; only genuinely shared config belongs in `shared_scripts` |
| "I'll use `dependency '/es_extended'` with a leading slash to be safe" | A leading slash marks the dependency as optional — if your resource genuinely requires ESX to function, it will silently start without it and crash later | Only use the leading slash for optional dependencies; use `dependency 'es_extended'` (no slash) when it is required |

## Output format

Return the corrected or complete manifest as a single `lua` code block. No prose wrapper. If explaining a mistake, append one line after the block naming what was wrong and why.

## Required fields

```lua
fx_version 'cerulean'
games { 'gta5' }          -- or { 'rdr3' } or { 'gta5', 'rdr3' }
```

`fx_version 'cerulean'` is the current version identifier; do not use older values like `'bodacious'` or `'adamant'`.

## Metadata fields

```lua
author 'AuthorName'
description 'Short description of what the resource does'
version '1.0.0'
```

All metadata fields are optional but strongly recommended for discoverability.

## Script declarations

```lua
shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua',
    'client/utils/*.lua'
}

server_scripts {
    'server/*.lua'
}
```

- `shared_scripts` — loaded on both client and server
- `client_scripts` — loaded only on client
- `server_scripts` — loaded only on server
- Single-file shorthand: `client_script 'client/main.lua'`
- Glob patterns: `'client/*.lua'` matches files in `client/` but not subdirectories; `'client/**/*.lua'` recurses

## Lua 5.4

All scripts run on Lua 5.4 by default. `lua54 'yes'` is **deprecated and must never be added**.

## Dependencies

```lua
dependency 'es_extended'    -- ESX framework
dependency 'qb-core'        -- QBCore framework
dependency 'oxmysql'        -- database
dependency '/oxmysql'       -- leading slash = optional dependency
```

- `dependency` causes the resource to fail to start if the dependency is not running
- Use the resource name exactly as it appears in `resources/`
- `/dependency` (leading slash) marks an optional dependency

## Provide and replace

```lua
provide 'mysql-async'       -- this resource satisfies 'mysql-async' dependency requests
replace 'OldResourceName'   -- this resource replaces an older one for dependency resolution
```

## NUI (web UI)

```lua
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
```

- `ui_page` sets the HTML entry point; must match the actual path
- `files` lists all assets the client needs to download
- Glob works: `'html/**'` includes everything in html/

## Data files

```lua
data_file 'DLC_ITYP_REQUEST' 'stream/vehicles.ytyp'
data_file 'HANDLING_FILE' 'data/handling.meta'
```

Data files are GTA-specific streaming assets. The first argument is the type; the second is the path relative to the resource root.

## JavaScript / Node.js

```lua
client_scripts {
    'client/*.js'
}

server_scripts {
    '@node_modules/dir',     -- only for native Node.js modules
    'server/*.js'
}
```

Client JS runs in Chromium (V8); server JS runs in Node.js. They are separate runtimes — `require()` works on server, not on client.

## C#

```lua
client_scripts {
    'Client/ClientMain.net.dll'
}

server_scripts {
    'Server/ServerMain.net.dll'
}
```

C# resources must be compiled; the manifest references the compiled DLL, not the source `.cs` files.

## Asset escrow

```lua
escrow_ignore {
    'config.lua'    -- this file is not escrowed even if the resource is
}
```

Used when publishing to the CFX asset store. Files in `escrow_ignore` are not obfuscated.

## Recommended field order

```lua
fx_version 'cerulean'
games { 'gta5' }

author 'Name'
description 'Description'
version '1.0.0'

dependency 'es_extended'

shared_scripts { 'config.lua' }
client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }

ui_page 'html/index.html'
files { 'html/**' }
```

## Common mistakes

| Mistake | Fix |
|---|---|
| Including `lua54 'yes'` | Remove it — deprecated and ignored |
| Using `__resource.lua` | Rename to `fxmanifest.lua`, update format |
| `games { 'gta5' }` on a RedM resource | Use `games { 'rdr3' }` |
| Missing `files {}` for NUI assets | Add all HTML/CSS/JS paths to `files` |
| Script file not loading | Check glob depth; single `*` doesn't recurse |
| `dependency` references wrong resource name | Match the actual folder name in `resources/` |
| Adding `@oxmysql/lib/MySQL.lua` to `client_scripts` | oxmysql must be in `server_scripts` only |
