local isOpen = false

RegisterCommand('openUI', function()
    if isOpen then return end
    isOpen = true

    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'show' })
end, false)

RegisterKeyMapping('openUI', 'Open UI', 'keyboard', Config.OpenKey)

RegisterNUICallback('close', function(data, cb)
    isOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hide' })
    cb('ok')
end)
