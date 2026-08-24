DonatorCB = {}

function RegisterDonatorCallback(name, fn)
    DonatorCB[name] = fn
end

RegisterNetEvent('dj-donator:server:cb', function(id, name, payload)
    local src = source
    local fn = DonatorCB[name]
    if not fn then
        TriggerClientEvent('dj-donator:client:cb', src, id, { ok = false, error = 'unknown_callback' })
        return
    end
    local ok, result = pcall(fn, src, payload or {})
    if not ok then
        print(('[dj-donator] callback %s failed: %s'):format(name, result))
        Webhooks.Error('Callback failed', ('%s: %s'):format(name, tostring(result)))
        TriggerClientEvent('dj-donator:client:cb', src, id, { ok = false, error = 'internal' })
        return
    end
    TriggerClientEvent('dj-donator:client:cb', src, id, result)
end)
