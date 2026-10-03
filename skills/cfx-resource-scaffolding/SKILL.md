---
name: cfx-resource-scaffolding
description: >-
  Scaffold a new FiveM or RedM resource from scratch — generates directory
  structure, fxmanifest.lua, and boilerplate scripts. Use when the user says
  "create a resource", "scaffold a FiveM resource", "new resource", "set up a
  resource from scratch", or "generate resource structure". NOT for editing an
  existing fxmanifest.lua (cfx-fxmanifest); NOT for git/PR/commit operations
  (dev-workflow); NOT for NUI UI design (cfx-nui).
model: sonnet
allowed-tools: [Read, Grep, Glob, Edit, Write]
last-verified: 2026-10-03
volatility: medium
---

# CFX Resource Scaffolding

Scaffold a new FiveM or RedM resource by collecting requirements, generating the full directory structure, correct manifest, and language-appropriate boilerplate.

## Iron Law

Always ask for all five requirements before generating any files, because generating a Lua+ESX manifest then discovering the user wanted JavaScript+standalone means every file is wrong — five questions up front cost less than a full regeneration.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll infer the framework from the resource name" | Names are unreliable; a resource called `my-shop` could be any framework | Ask explicitly; inference causes silent mismatches that show up at runtime |
| "I'll skip the database question since most resources don't need it" | Omitting the oxmysql server_script entry means the resource silently fails to load queries at first use | Ask explicitly; it's one question |
| "I'll add `lua54 'yes'` for safety since Lua 5.4 is newer" | `lua54 'yes'` is deprecated and ignored; writing it signals ignorance to the repo owner and may confuse LSP tooling | Never include it; all scripts run on Lua 5.4 by default |
| "I'll skip the README since developers know what they're building" | Without docs the resource becomes unmaintainable within weeks; future contributors (including the author) need context | Always generate a minimal README with resource name, purpose, and dependency list |
| "I'll add all common dependencies by default just in case" | Unused dependencies delay resource start and fail if the dependency is not running on the server | Only add what was explicitly confirmed during intake |
| "I'll put oxmysql in client_scripts for easy access" | oxmysql is a server-side library; adding it to client_scripts does nothing and confuses future maintainers | oxmysql belongs in `server_scripts` only — `'@oxmysql/lib/MySQL.lua'` before your server scripts |

## Output format

Write files directly using the Write tool when the request is inside an existing resource directory. Otherwise output each file as a labelled code block. Always list the generated file paths as a checklist at the end so the user knows what to place where.

## Workflow

| User intent | Action |
|---|---|
| New resource from nothing | Run the five-question intake below, then generate all files |
| "Just create the manifest" | Route to cfx-fxmanifest instead |
| "Add NUI to this resource" | Route to cfx-nui after scaffolding |

## Intake — ask before generating

1. **Resource name** — lowercase, alphanumeric with hyphens (e.g. `my-resource`)
2. **Game target** — `gta5` (FiveM), `rdr3` (RedM), or both
3. **Language runtime** — Lua, JavaScript, or C#
4. **Framework** — ESX, QBCore, Qbox, ox_core, VORP (RedM), RSG (RedM), or standalone
5. **Database needed?** — yes/no (determines oxmysql dependency)

## Directory structure by language

### Lua (default)

```
resource-name/
  fxmanifest.lua
  config.lua
  client/
    main.lua
  server/
    main.lua
  README.md
```

### JavaScript

```
resource-name/
  fxmanifest.lua
  package.json
  client/
    main.js
  server/
    main.js
  README.md
```

### C#

```
resource-name/
  fxmanifest.lua
  MyResource.csproj
  Client/
    ClientMain.cs
  Server/
    ServerMain.cs
  README.md
```

## fxmanifest.lua generation

Base structure — always use this:

```lua
fx_version 'cerulean'
games { 'gta5' }          -- or { 'rdr3' } or { 'gta5', 'rdr3' }

author 'AuthorName'
description 'Resource description'
version '1.0.0'
```

Never add `lua54 'yes'` — it is deprecated and ignored. All scripts run on Lua 5.4 by default.

### Script declarations by language

**Lua:**
```lua
shared_scripts {
    'config.lua'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}
```

**JavaScript:**
```lua
client_scripts {
    'client/*.js'
}

server_scripts {
    'server/*.js'
}
```

**C#:**
```lua
client_scripts {
    'Client/ClientMain.net.dll'
}

server_scripts {
    'Server/ServerMain.net.dll'
}
```

### Framework dependency directives

| Framework | Directive |
|---|---|
| ESX | `dependency 'es_extended'` |
| QBCore | `dependency 'qb-core'` |
| Qbox | `dependency 'qbx_core'` |
| ox_core | `dependency 'ox_core'` |
| VORP (RedM) | `dependency 'vorp_core'` |
| RSG (RedM) | `dependency 'rsg-core'` |
| Standalone | (no dependency directive) |

### Database dependency (if yes)

Add to `server_scripts`:

```lua
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua'
}
```

## Starter boilerplate by language

### Lua — client

```lua
local Config = Config or {}

CreateThread(function()
    while true do
        Wait(1000)
        -- Main client loop
    end
end)
```

### Lua — server

```lua
local Config = Config or {}

RegisterNetEvent('resourceName:serverEvent', function(data)
    local source = source
    -- Validate source and handle event
end)
```

### Lua — config

```lua
Config = {}

Config.Debug = false
-- Add configurable values here
```

### JavaScript — client

```js
setTick(async () => {
    await Delay(1000);
    // main client tick
});
```

### JavaScript — server

```js
onNet('resourceName:serverEvent', (data) => {
    const src = source;
    // validate and handle
});
```

### C# — client

```csharp
using CitizenFX.Core;

public class ClientMain : BaseScript
{
    public ClientMain()
    {
        Tick += OnTick;
    }

    private async Task OnTick()
    {
        await Delay(1000);
        // main client loop
    }
}
```

### C# — server

```csharp
using CitizenFX.Core;

public class ServerMain : BaseScript
{
    public ServerMain()
    {
        EventHandlers["resourceName:serverEvent"] += new Action<Player, dynamic>(OnServerEvent);
    }

    private void OnServerEvent([FromSource] Player player, dynamic data)
    {
        // handle event
    }
}
```

> **C# requires a build step.** The fxmanifest references the compiled `.net.dll` output, not the `.cs` source files. After scaffolding, compile with `dotnet build` before adding the resource to your server — the DLL must exist at the path declared in the manifest or the resource will fail to start.

## Post-generation checklist

Remind the user to:

1. Update the `author` field in fxmanifest.lua
2. Update the `description` field
3. Add the resource folder to their server's `resources/` directory
4. Add `ensure resource-name` to their server.cfg
5. Customize config.lua with their settings
