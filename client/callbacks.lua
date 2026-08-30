local pending = {}
local seq = 0

function DonatorCallback(name, payload)
    seq = seq + 1
    local id = seq
    local p = promise.new()
    pending[id] = p
    TriggerServerEvent('djfivem-305donator:server:cb', id, name, payload or {})
    return Citizen.Await(p)
end

RegisterNetEvent('djfivem-305donator:client:cb', function(id, result)
    local p = pending[id]
    if p then
        pending[id] = nil
        p:resolve(result or { ok = false })
    end
end)
