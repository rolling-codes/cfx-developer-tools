local ESX = exports['es_extended']:getSharedObject()

local playerData = {}

AddEventHandler('esx:playerLoaded', function(data)
    playerData = data
end)

AddEventHandler('esx:setJob', function(job)
    playerData.job = job
end)

RegisterNetEvent('myResource:clientAction', function(data)
    -- handle server → client event
end)
