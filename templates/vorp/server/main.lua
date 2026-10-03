local VORPcore = exports.vorp_core:GetCore()

RegisterNetEvent('myResource:serverEvent', function(data)
    local src = source
    if not src or src <= 0 then return end

    local User = VORPcore.GetUser(src)
    if not User then return end

    -- User.getUsedCharacter.job, User.getUsedCharacter.money, etc.
end)
