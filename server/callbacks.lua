DonatorCB = {}

function RegisterDonatorCallback(name, fn)
    DonatorCB[name] = fn
end

RegisterNetEvent('djfivem-305donator:server:cb', function(id, name, payload)
    local src = source
    local fn = DonatorCB[name]
    if not fn then
        TriggerClientEvent('djfivem-305donator:client:cb', src, id, { ok = false, error = 'unknown_callback' })
        return
    end
    local ok, result = pcall(fn, src, payload or {})
    if not ok then
        print(('[djfivem-305donator] callback %s failed: %s'):format(name, result))
        Webhooks.Error('Callback failed', ('%s: %s'):format(name, tostring(result)))
        TriggerClientEvent('djfivem-305donator:client:cb', src, id, { ok = false, error = 'internal' })
        return
    end
    TriggerClientEvent('djfivem-305donator:client:cb', src, id, result)
end)
