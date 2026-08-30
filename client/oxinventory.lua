local petModels = {
    pet_husky = 'a_c_husky',
    pet_retriever = 'a_c_retriever',
    pet_rottweiler = 'a_c_rottweiler',
    pet_pug = 'a_c_pug',
    pet_cat = 'a_c_cat_01',
    pet_poodle = 'a_c_poodle',
    lim_panther = 'a_c_panther',
}

local function spawnFromItem(data)
    local meta = data and data.metadata or {}
    local name = data and (data.name or data.item) or ''
    local model = meta.petModel or petModels[name]
    local label = meta.label or (data and data.label) or 'Pet'
    if not model then
        return
    end
    if GetActivePetLabel() then
        TriggerEvent('djfivem-305donator:client:despawnPet')
        Wait(200)
    end
    TriggerEvent('djfivem-305donator:client:spawnPet', model, label)
end

--- ox_inventory client export: client.export = 'djfivem-305donator.usePet'
exports('usePet', function(data, slot)
    local payload = data or slot or {}
    if GetResourceState('ox_inventory') == 'started' and payload.name then
        exports.ox_inventory:useItem(payload, function(verified)
            if verified then
                spawnFromItem(verified)
            else
                spawnFromItem(payload)
            end
        end)
        return
    end
    spawnFromItem(payload)
end)
