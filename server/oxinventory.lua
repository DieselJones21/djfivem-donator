-- ox_inventory bridge: item images, CanCarry, AddItem, RemoveItem, usable pets.

OxInv = {
    ready = false,
    resource = 'ox_inventory',
}

local function started()
    return GetResourceState(OxInv.resource) == 'started'
end

function OxInv.Ready()
    return OxInv.ready and started()
end

local function imageBase()
    local path = GetConvar('inventory:imagepath', 'nui://ox_inventory/web/images')
    return path:gsub('/$', '')
end

function OxInv.GetItem(name)
    if not OxInv.Ready() or not name then
        return nil
    end
    local ok, data = pcall(function()
        return exports.ox_inventory:Items(name)
    end)
    if ok and data then
        return data
    end
end

function OxInv.ResolveName(name)
    if not name or name == '' then
        return nil
    end
    if OxInv.GetItem(name) then
        return name
    end
    local upper = name:upper()
    if upper ~= name and OxInv.GetItem(upper) then
        return upper
    end
    local lower = name:lower()
    if lower ~= name and OxInv.GetItem(lower) then
        return lower
    end
    if not name:upper():find('^WEAPON_') then
        local weapon = 'WEAPON_' .. name:gsub('^[Ww][Ee][Aa][Pp][Oo][Nn]_', ''):upper()
        if OxInv.GetItem(weapon) then
            return weapon
        end
    end
    return nil
end

function OxInv.Image(name)
    local resolved = OxInv.ResolveName(name) or name
    if not resolved then
        return nil
    end
    local data = OxInv.GetItem(resolved)
    if data and data.client and data.client.image then
        local img = data.client.image
        if img:find('://') then
            return img
        end
        if img:find('%.') then
            return ('%s/%s'):format(imageBase(), img)
        end
        return ('%s/%s.png'):format(imageBase(), img)
    end
    return ('%s/%s.png'):format(imageBase(), resolved:lower())
end

function OxInv.Describe(name)
    local resolved = OxInv.ResolveName(name)
    local data = resolved and OxInv.GetItem(resolved) or nil
    return resolved, data, OxInv.Image(resolved or name)
end

function OxInv.GrantsFor(item)
    local grants = {}
    if item.weapon or (item.item and not item.extras) then
        local metadata = {}
        if item.ammo then
            metadata.ammo = item.ammo
        end
        if item.metadata then
            for k, v in pairs(item.metadata) do
                metadata[k] = v
            end
        end
        metadata.description = ('%s • %s'):format(item.label or 'Donator', Config.ServerName)
        grants[#grants + 1] = {
            name = item.item or item.weapon,
            count = 1,
            metadata = metadata,
        }
    end
    if item.extras then
        for i = 1, #item.extras do
            local extra = item.extras[i]
            grants[#grants + 1] = {
                name = extra.item,
                count = extra.count or 1,
                metadata = extra.metadata,
            }
        end
    end
    if item.petModel then
        grants[#grants + 1] = {
            name = item.id,
            count = 1,
            metadata = {
                petModel = item.petModel,
                label = item.label,
                description = ('Use to spawn or dismiss your %s.'):format(item.label or 'pet'),
            },
        }
    end
    return grants
end

function OxInv.DecoratePublic(pub, raw)
    if not pub then
        return pub
    end
    local grants = OxInv.GrantsFor(raw)
    pub.ox = { grants = {}, registered = true, inventory = 'ox' }
    for i = 1, #grants do
        local resolved, data, image = OxInv.Describe(grants[i].name)
        pub.ox.grants[#pub.ox.grants + 1] = {
            name = resolved or grants[i].name,
            count = grants[i].count,
            label = data and data.label or grants[i].name,
            image = image,
            weight = data and data.weight or 0,
            registered = resolved ~= nil,
        }
        if not resolved then
            pub.ox.registered = false
        end
    end
    if (not pub.image or pub.image == '') and pub.ox.grants[1] and pub.ox.grants[1].image then
        pub.image = pub.ox.grants[1].image
    end
    return pub
end

function OxInv.PlayerInfo(source)
    if not OxInv.Ready() then
        return nil
    end
    local ok, inv = pcall(function()
        return exports.ox_inventory:GetInventory(source)
    end)
    if not ok or not inv then
        return nil
    end
    return {
        weight = inv.weight or 0,
        maxWeight = inv.maxWeight or 0,
        slots = inv.slots or 0,
    }
end

function OxInv.CanCarryGrants(source, grants)
    if not OxInv.Ready() then
        return true
    end
    for i = 1, #grants do
        local name = OxInv.ResolveName(grants[i].name)
        if not name then
            return false, 'invalid_item', grants[i].name
        end
        local count = grants[i].count or 1
        local can = exports.ox_inventory:CanCarryItem(source, name, count, grants[i].metadata)
        if not can then
            return false, 'cannot_carry', name
        end
    end
    return true
end

function OxInv.Add(source, name, count, metadata)
    count = count or 1
    local resolved = OxInv.ResolveName(name)
    if not resolved then
        return false, 'invalid_item'
    end
    metadata = metadata or {}
    if resolved == 'donator_plate' or resolved == 'penthouse_card' or resolved == 'lim_panther' or resolved:find('^pet_') then
        metadata.imageurl = metadata.imageurl or ('nui://dj-donator/html/images/%s.png'):format(resolved)
    end
    local ok, success, response = pcall(function()
        return exports.ox_inventory:AddItem(source, resolved, count, metadata)
    end)
    if not ok then
        print(('[dj-donator] ox_inventory AddItem failed: %s'):format(tostring(success)))
        return false, 'internal'
    end
    return success and true or false, response, resolved
end

function OxInv.Remove(source, name, count, metadata)
    count = count or 1
    local resolved = OxInv.ResolveName(name)
    if not resolved then
        return false
    end
    local ok, success = pcall(function()
        return exports.ox_inventory:RemoveItem(source, resolved, count, metadata)
    end)
    return ok and success and true or false
end

function OxInv.Rollback(source, added)
    if not added then
        return
    end
    for i = 1, #added do
        OxInv.Remove(source, added[i].name, added[i].count, added[i].metadata)
    end
end

function OxInv.GiveGrants(source, grants)
    if not grants or #grants == 0 then
        return true, {}
    end
    if not OxInv.Ready() then
        return false, 'ox_missing'
    end
    local added = {}
    for i = 1, #grants do
        local success, err, resolved = OxInv.Add(source, grants[i].name, grants[i].count, grants[i].metadata)
        if not success then
            OxInv.Rollback(source, added)
            return false, err or 'inventory_full', grants[i].name
        end
        added[#added + 1] = { name = resolved or grants[i].name, count = grants[i].count, metadata = grants[i].metadata }
    end
    return true, added
end

function OxInv.RemoveGrants(source, item)
    if not source or not OxInv.Ready() then
        return
    end
    local grants = OxInv.GrantsFor(item)
    for i = 1, #grants do
        OxInv.Remove(source, grants[i].name, grants[i].count)
    end
end

CreateThread(function()
    local deadline = GetGameTimer() + 20000
    while GetGameTimer() < deadline and not started() do
        Wait(200)
    end
    OxInv.ready = started()
    if OxInv.ready then
        print('[dj-donator] Linked with ox_inventory for images, weight checks, and item grants.')
    else
        print('[dj-donator] WARNING: ox_inventory is not started. Item grants and images will not work.')
    end
end)
