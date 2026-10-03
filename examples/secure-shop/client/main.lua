local nearShop = false

-- Proximity detection
CreateThread(function()
    while true do
        local coords  = GetEntityCoords(PlayerPedId())
        local wasNear = nearShop
        nearShop      = #(coords - Config.ShopCoords) < Config.ShopRange

        if nearShop and not wasNear then
            -- In production: show shop UI or help text
            print('[Shop] Press E to open shop')
        elseif not nearShop and wasNear then
            print('[Shop] Left shop area')
        end

        Wait(nearShop and 500 or 1000)
    end
end)

-- Open shop (client sends item name + quantity — NOT price)
RegisterCommand('buyItem', function(src, args)
    if not nearShop then
        print('[Shop] Too far from shop.')
        return
    end

    local itemName = args[1]
    local quantity = tonumber(args[2]) or 1

    if not itemName then
        print('[Shop] Usage: /buyItem <item> <quantity>')
        return
    end

    TriggerServerEvent('shop:buy', itemName, quantity)
end, false)

-- Feedback from server
RegisterNetEvent('shop:result', function(success, msg)
    print('[Shop] ' .. (success and 'Purchase OK: ' or 'Failed: ') .. msg)
end)
