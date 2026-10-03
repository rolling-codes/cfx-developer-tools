local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('myResource:serverEvent', function(data)
    local src = source
    if not src or src <= 0 then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- use Player.PlayerData.job.name, Player.Functions.GetMoney('cash'), etc.
end)
