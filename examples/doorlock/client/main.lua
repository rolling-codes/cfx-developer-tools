local nearestDoor = nil

-- Poll for proximity — run faster only when near a door
CreateThread(function()
    while true do
        local ped    = PlayerPedId()
        local coords = GetEntityCoords(ped)

        nearestDoor = nil
        for i, door in ipairs(Config.Doors) do
            if #(coords - door.coords) < Config.InteractRange then
                nearestDoor = i
                break
            end
        end

        Wait(nearestDoor and 0 or 500)
    end
end)

-- Player requests a toggle — server validates range and rate-limit
RegisterCommand('toggleDoor', function()
    if not nearestDoor then return end
    TriggerServerEvent('doorlock:toggle', nearestDoor)
end, false)

RegisterKeyMapping('toggleDoor', 'Toggle nearby door lock', 'keyboard', 'G')

-- React to state changes pushed by the server
for i, door in ipairs(Config.Doors) do
    AddStateBagChangeHandler('door_' .. i .. '_locked', 'global', function(_, _, locked)
        -- In production: DoorSystemSetDoorState, prop freeze, or prop swap here.
        -- This example just logs the change.
        local label = door.label or ('Door ' .. i)
        print(label .. ' is now ' .. (locked and 'LOCKED' or 'UNLOCKED'))
    end)
end
