local doorStates = {}   -- index → bool (true = locked)
local cooldowns   = {}  -- src   → last toggle timestamp (ms)

local COOLDOWN_MS = 1000

-- Initialise GlobalState for each door
AddEventHandler('onResourceStart', function(name)
    if GetCurrentResourceName() ~= name then return end
    for i = 1, #Config.Doors do
        doorStates[i] = false
        GlobalState:set('door_' .. i .. '_locked', false, true)
    end
end)

RegisterNetEvent('doorlock:toggle', function(doorIndex)
    local src = source
    if not src or src <= 0 then return end

    local door = Config.Doors[doorIndex]
    if not door then return end  -- reject invalid index

    -- Rate limit: one toggle per second per player
    local now = GetGameTimer()
    if cooldowns[src] and (now - cooldowns[src]) < COOLDOWN_MS then return end
    cooldowns[src] = now

    -- Server-side range check — never trust client-reported position
    local ped    = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    if #(pCoords - door.coords) > Config.InteractRange then return end

    -- Toggle and broadcast via GlobalState
    doorStates[doorIndex] = not doorStates[doorIndex]
    GlobalState:set('door_' .. doorIndex .. '_locked', doorStates[doorIndex], true)
end)

-- Clean up cooldown table on disconnect to avoid memory growth
AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
