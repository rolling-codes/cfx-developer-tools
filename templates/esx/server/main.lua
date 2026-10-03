local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('myResource:serverEvent', function(data)
    local src = source
    if not src or src <= 0 then return end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then return end

    -- use xPlayer.job.name, xPlayer.getMoney(), xPlayer.addMoney(), etc.
end)
