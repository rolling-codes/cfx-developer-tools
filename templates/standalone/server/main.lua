RegisterNetEvent('myResource:serverEvent', function(data)
    local src = source
    if not src or src <= 0 then return end

    -- server logic here
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    print('^2' .. resourceName .. ' started^7')
end)
