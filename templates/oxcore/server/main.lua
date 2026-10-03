require '@ox_core.lib.init'

RegisterNetEvent('myResource:serverEvent', function(data)
    local src = source
    if not src or src <= 0 then return end

    local player = Ox.GetPlayer(src)
    if not player then return end

    -- player.group (replaces job/gang), player.charId
end)
