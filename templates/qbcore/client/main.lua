local QBCore = exports['qb-core']:GetCoreObject()

local PlayerData = {}

AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

AddEventHandler('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

RegisterNetEvent('myResource:clientAction', function(data)
    -- handle server → client event
end)
