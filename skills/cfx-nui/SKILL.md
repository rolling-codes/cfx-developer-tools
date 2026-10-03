---
name: cfx-nui
description: >-
  Guide NUI (in-game web UI) development for FiveM and RedM — manifest wiring,
  Lua-to-NUI messaging, NUI-to-Lua callbacks, focus management, debugging, and
  common patterns. Use when the user asks about "NUI", "in-game UI",
  "SendNUIMessage", "RegisterNuiCallback", "ui_page", "HTML interface",
  "Chromium overlay", "NUI focus", or "in-game browser". NOT for general
  fxmanifest.lua editing beyond NUI fields (cfx-fxmanifest); NOT for
  client/server event patterns (cfx-client-server).
model: sonnet
allowed-tools: [Read, Grep, Glob, Edit, Write]
last-verified: 2026-10-03
volatility: medium
---

# CFX NUI Development

NUI (Natural User Interface) is a Chromium-based embedded browser in the FiveM/RedM game client. Resources render HTML/CSS/JS interfaces overlaid on the game screen.

## Iron Law

Always call `SetNuiFocus(false, false)` when the NUI is closed and the user returns to the game, because leaving NUI focus active traps mouse and keyboard input inside the browser — the player cannot move, aim, or interact with the game world.

## Red Flags

| Excuse | Why it's wrong | What to do instead |
|---|---|---|
| "I'll skip `SetNuiFocus(false, false)` since the UI auto-hides" | Hiding the UI does not release focus; the game still captures inputs for the invisible browser | Always pair open/close: `SetNuiFocus(true, true)` on open, `SetNuiFocus(false, false)` on close |
| "I'll use `fetch()` from NUI to call the server directly" | NUI runs sandboxed in Chromium; it cannot reach the FiveM server directly | Use `RegisterNuiCallback` on the Lua client side as the bridge; NUI talks to Lua, Lua talks to the server |
| "I'll add the NUI HTML files to `server_scripts`" | NUI assets must be in `files {}` in the manifest so the client can download them; server_scripts are irrelevant | Add HTML/CSS/JS to `files {}` and use `ui_page` to set the entry point |
| "I'll call `RegisterNuiCallback` from inside the NUI JavaScript" | `RegisterNuiCallback` is a FiveM client-script global, not a browser API — it does not exist inside the Chromium NUI context | Call it in your Lua (or JS resource script) client file, not in the HTML page's script |
| "I'll store player data in NUI `localStorage` for persistence across sessions" | `localStorage` is per-machine browser profile; different user accounts share it, and it's wiped on game reinstall or profile reset | Persist player data server-side; send it to NUI fresh on each open via `SendNUIMessage` |

## Output format

When the request involves Lua↔NUI messaging, always output both sides together in labelled blocks (`-- Lua (client)` and `// JavaScript (NUI)`). Never show one side without the other for messaging patterns.

## Manifest setup

```lua
ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js'
}
```

- `ui_page` sets the HTML entry point
- `files` lists all assets the client downloads; glob patterns work (`'html/**'`)
- Without `files`, assets 404 silently

## Communication: Lua → NUI

Send data from Lua client script to the NUI:

```lua
-- In a client Lua script
SendNUIMessage({
    type = 'open',
    data = {
        playerName = GetPlayerName(PlayerId()),
        money = 500
    }
})
```

Handle in JavaScript:

```js
window.addEventListener('message', (event) => {
    const data = event.data;
    if (data.type === 'open') {
        document.getElementById('name').textContent = data.data.playerName;
        document.querySelector('.ui').style.display = 'block';
    }
});
```

## Communication: NUI → Lua

Register a callback on the Lua side:

```lua
-- In a client Lua script
RegisterNuiCallback('close', function(data, cb)
    SetNuiFocus(false, false)
    -- data is the object passed from JS
    cb({ success = true })  -- must always call cb to resolve the fetch
end)
```

Trigger from JavaScript:

```js
// Must use fetch() with the cfx:// scheme
async function closeUI() {
    const resp = await fetch(`https://${GetParentResourceName()}/close`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ reason: 'user closed' })
    });
    const data = await resp.json();
    // data = { success: true }
}
```

`GetParentResourceName()` returns the resource name at runtime — always use it instead of hardcoding.

## Focus management

```lua
-- Open UI and grant focus (mouse + keyboard)
SendNUIMessage({ type = 'show' })
SetNuiFocus(true, true)

-- Close UI and release focus
SendNUIMessage({ type = 'hide' })
SetNuiFocus(false, false)
```

`SetNuiFocus(hasFocus, hasCursor)`:
- `hasFocus = true` — keyboard input goes to NUI
- `hasCursor = true` — mouse cursor is visible and interactive in NUI
- Both false: game regains full control

## Framework choices for NUI

| Choice | Use when |
|---|---|
| Vanilla HTML/CSS/JS | Simple UI, no build step needed, prefer fewer dependencies |
| Vue 3 (CDN) | Reactive data binding without a build step |
| React (bundled) | Complex UI, existing React knowledge, willing to add a build step |
| ox_lib (built-in UI) | Server already uses ox_lib; reuse its styled components |

Avoid heavy frontend frameworks for simple in-game UIs — they add unnecessary load time and complexity.

## Limitations

- NUI runs in a sandboxed Chromium — no Node.js APIs
- `localStorage` works but is cleared between game sessions on some setups; use server-side storage for persistence
- Cross-origin requests are blocked; all external API calls must go through the Lua server side
- Audio/video autoplay may be blocked; use user interaction to trigger media
- CSS `position: fixed` works relative to the game overlay, not the browser viewport

## Debugging

In the F8 client console (press F8 in-game to open it), run:

```
nui_devtools ResourceName
```

This opens a separate Chromium DevTools window for the resource's NUI page. Use it to inspect the DOM, check console errors, and set breakpoints in JavaScript.

To check NUI errors without DevTools:

```lua
-- Add to client script
AddEventHandler('onClientResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        -- NUI is ready after resource start
    end
end)
```

## Common patterns

### Toggle UI on key press

```lua
local isOpen = false

RegisterCommand('toggleui', function()
    isOpen = not isOpen
    SendNUIMessage({ type = isOpen and 'show' or 'hide' })
    SetNuiFocus(isOpen, isOpen)
end)
```

### Send server data to NUI

```lua
-- Client: request data from server, then forward to NUI
RegisterNetEvent('myResource:receiveData', function(data)
    SendNUIMessage({ type = 'setData', data = data })
end)

TriggerServerEvent('myResource:requestData')
```

### Submit form from NUI

```js
// JavaScript (NUI)
document.getElementById('submitBtn').addEventListener('click', async () => {
    const value = document.getElementById('input').value;
    await fetch(`https://${GetParentResourceName()}/submit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ value })
    });
});
```

```lua
-- Lua (client)
RegisterNuiCallback('submit', function(data, cb)
    TriggerServerEvent('myResource:onSubmit', data.value)
    SetNuiFocus(false, false)
    cb({ ok = true })
end)
```
