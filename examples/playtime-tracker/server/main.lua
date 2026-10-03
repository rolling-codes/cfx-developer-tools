local sessionStart = {}  -- [src] → os.time() of connect

local FLUSH_INTERVAL_MS = 5 * 60 * 1000  -- flush to DB every 5 minutes

local function getIdentifier(src)
    return GetPlayerIdentifierByType(src, 'license')
end

-- Upsert helper: create row if missing, then add elapsed seconds
local function addSeconds(identifier, elapsed)
    if elapsed <= 0 then return end
    MySQL.query('INSERT INTO player_playtime (identifier, seconds) VALUES (?, ?) '
        .. 'ON DUPLICATE KEY UPDATE seconds = seconds + VALUES(seconds)',
        { identifier, elapsed })
end

-- Start tracking when a player connects
AddEventHandler('playerConnecting', function()
    local src = source
    sessionStart[src] = os.time()
end)

-- Flush session on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if not sessionStart[src] then return end

    local identifier = getIdentifier(src)
    if identifier then
        addSeconds(identifier, os.time() - sessionStart[src])
    end

    sessionStart[src] = nil
end)

-- Periodic flush so data isn't lost to crashes
CreateThread(function()
    while true do
        Wait(FLUSH_INTERVAL_MS)
        local now = os.time()
        for src, start in pairs(sessionStart) do
            local identifier = getIdentifier(src)
            if identifier then
                addSeconds(identifier, now - start)
                sessionStart[src] = now  -- reset window after flush
            end
        end
    end
end)

-- /playtime [optional-target-id]
RegisterCommand('playtime', function(src, args)
    local target     = tonumber(args[1]) or src
    local identifier = getIdentifier(target)

    if not identifier then
        TriggerClientEvent('chat:addMessage', src, { args = { '[Playtime]', 'Player not found.' } })
        return
    end

    local stored = MySQL.scalar.await(
        'SELECT seconds FROM player_playtime WHERE identifier = ?',
        { identifier }
    ) or 0

    -- Add current in-session time
    local inSession = sessionStart[target] and (os.time() - sessionStart[target]) or 0
    local total   = stored + inSession

    local hours   = math.floor(total / 3600)
    local minutes = math.floor((total % 3600) / 60)

    local name = GetPlayerName(target) or ('Player ' .. target)
    TriggerClientEvent('chat:addMessage', src, {
        args = { '[Playtime]', ('%s: %dh %dm'):format(name, hours, minutes) }
    })
end, false)
