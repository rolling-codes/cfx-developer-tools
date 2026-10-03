-- Qbox: access core via exports, not a shared object variable
local PlayerData = {}

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = exports['qbx_core']:GetPlayerData()
end)

AddEventHandler('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

RegisterNetEvent('myResource:clientAction', function(data)
    lib.notify({ title = 'Notification', description = data.message or '', type = 'inform' })
end)
