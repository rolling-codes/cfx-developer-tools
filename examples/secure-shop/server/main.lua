local cooldowns = {}  -- [src] → last purchase timestamp (ms)

-- Replace these stubs with your framework's money/inventory calls
local function getPlayerMoney(src)
    return 1000  -- stub — replace with ESX/QBCore/ox_core call
end

local function removeMoney(src, amount)
    return true  -- stub — replace; return false if player cannot afford
end

local function giveItem(src, itemName, quantity)
    return true  -- stub — replace with your inventory call
end

RegisterNetEvent('shop:buy', function(itemName, quantity)
    local src = source
    if not src or src <= 0 then return end

    -- 1. Type safety
    if type(itemName) ~= 'string' then return end
    if type(quantity) ~= 'number' then return end

    -- 2. Positive integer quantity
    if quantity < 1 or quantity ~= math.floor(quantity) then
        TriggerClientEvent('shop:result', src, false, 'Invalid quantity.')
        return
    end

    -- 3. Item exists in server catalogue (client never knows the price)
    local item = Config.Items[itemName]
    if not item then
        TriggerClientEvent('shop:result', src, false, 'Unknown item.')
        return
    end

    -- 4. Max stack enforcement
    if quantity > item.maxStack then
        TriggerClientEvent('shop:result', src, false, 'Exceeds max stack.')
        return
    end

    -- 5. Anti-spam cooldown
    local now = GetGameTimer()
    if cooldowns[src] and (now - cooldowns[src]) < Config.CooldownMs then
        TriggerClientEvent('shop:result', src, false, 'Too fast.')
        return
    end
    cooldowns[src] = now

    -- 6. Server-side range check
    local ped     = GetPlayerPed(src)
    local pCoords = GetEntityCoords(ped)
    if #(pCoords - Config.ShopCoords) > Config.ShopRange then
        TriggerClientEvent('shop:result', src, false, 'Not near shop.')
        return
    end

    -- 7. Afford check (price computed server-side only)
    local total = item.price * quantity
    if getPlayerMoney(src) < total then
        TriggerClientEvent('shop:result', src, false, 'Insufficient funds.')
        return
    end

    -- 8. Deduct then grant — refund if grant fails
    if not removeMoney(src, total) then
        TriggerClientEvent('shop:result', src, false, 'Payment failed.')
        return
    end

    if not giveItem(src, itemName, quantity) then
        -- Roll back the payment to avoid item-less money deduction
        removeMoney(src, -total)
        TriggerClientEvent('shop:result', src, false, 'Inventory full.')
        return
    end

    TriggerClientEvent('shop:result', src, true,
        ('Bought %dx %s for $%d.'):format(quantity, item.label, total))
end)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)
