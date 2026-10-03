require '@ox_core.lib.init'

RegisterNetEvent('myResource:clientAction', function(data)
    lib.notify({ title = 'Notification', description = data.message or '', type = 'inform' })
end)

CreateThread(function()
    local player = Ox.GetPlayer()
    -- player.group, player.charId, cache.serverId (from ox_lib)
end)
