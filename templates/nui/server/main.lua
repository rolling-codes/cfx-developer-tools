-- Server-side placeholder — most NUI resources need server calls for data
RegisterNetEvent('myResource:getData', function()
    local src = source
    if not src or src <= 0 then return end

    TriggerClientEvent('myResource:receiveData', src, { message = 'Hello from server' })
end)
