local RSGCore = exports['rsg-core']:GetCoreObject()

local PlayerData = {}

AddEventHandler('RSGCore:Client:OnPlayerLoaded', function()
    PlayerData = RSGCore.Functions.GetPlayerData()
end)

RegisterNetEvent('myResource:clientAction', function(data)
    -- handle server → client event
end)
