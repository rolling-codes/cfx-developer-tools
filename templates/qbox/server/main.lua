RegisterNetEvent('myResource:serverEvent', function(data)
    local src = source
    if not src or src <= 0 then return end

    local player = exports['qbx_core']:GetPlayer(src)
    if not player then return end

    -- use player.PlayerData.job.name, player.Functions.GetMoney('cash'), etc.
end)
