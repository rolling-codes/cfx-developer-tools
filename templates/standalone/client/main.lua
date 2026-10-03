CreateThread(function()
    while true do
        Wait(1000)
        -- client loop
    end
end)

RegisterNetEvent('myResource:clientAction', function(data)
    -- handle server → client event
end)
