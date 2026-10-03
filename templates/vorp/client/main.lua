local VORPcore = exports.vorp_core:GetCore()

RegisterNetEvent('myResource:clientAction', function(data)
    VORPcore.NotifyRightTip(data.message or 'Notification', 4000)
end)
