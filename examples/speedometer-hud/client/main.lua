local hudVisible  = false
local UPDATE_RATE = 100  -- ms between NUI updates when in vehicle

CreateThread(function()
    while true do
        local ped     = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)

        if vehicle ~= 0 then
            if not hudVisible then
                hudVisible = true
                SendNUIMessage({ action = 'show' })
            end

            local speed    = GetEntitySpeed(vehicle)
            local gear     = GetVehicleCurrentGear(vehicle)
            local rpm      = GetVehicleCurrentRpm(vehicle)

            SendNUIMessage({
                action   = 'update',
                speedKph = math.floor(speed * 3.6),
                speedMph = math.floor(speed * 2.237),
                gear     = gear,
                rpm      = math.floor(rpm * 100),
            })

            Wait(UPDATE_RATE)   -- yield every 100 ms while driving
        else
            if hudVisible then
                hudVisible = false
                SendNUIMessage({ action = 'hide' })
            end
            Wait(500)           -- only check twice a second when on foot
        end
    end
end)
