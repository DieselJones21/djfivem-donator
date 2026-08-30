Listings = {}

local PREFIX = {
    vehicles = 'veh',
    weapons = 'wep',
    extras = 'ext',
    bundles = 'bdl',
    pets = 'pet',
    exclusives = 'ex',
    limited = 'lim',
}

local CATEGORIES = {
    vehicles = true,
    weapons = true,
    extras = true,
    bundles = true,
    pets = true,
    exclusives = true,
    limited = true,
}

local TIERS = {
    emerald = true,
    sapphire = true,
    blackdiamond = true,
}

local function trim(value)
    if type(value) ~= 'string' then
        return ''
    end
    return value:match('^%s*(.-)%s*$') or ''
end

local function slug(value)
    local s = trim(value):lower():gsub('[^a-z0-9]+', '_'):gsub('^_+', ''):gsub('_+$', '')
    if s == '' then
        s = 'listing'
    end
    return s:sub(1, 40)
end

local function toBool(value)
    return value == true or value == 1 or value == '1' or value == 'true' or value == 'on'
end

local function toInt(value, fallback)
    local n = tonumber(value)
    if n == nil then
        return fallback
    end
    return math.floor(n)
end

local function parseExtras(payload)
    local raw = payload and (payload.bundleItems or payload.extras)
    if type(raw) == 'string' and raw ~= '' then
        local ok, decoded = pcall(json.decode, raw)
        if ok then
            raw = decoded
        else
            return {}
        end
    end
    if type(raw) ~= 'table' then
        return {}
    end
    local extras = {}
    local function push(row)
        if type(row) ~= 'table' then
            return
        end
        local name = trim(row.item or row.name or '')
        local count = math.max(1, toInt(row.count, 1))
        if name ~= '' then
            extras[#extras + 1] = { item = name, count = count }
        end
    end
    -- JSON arrays are 1-based; some NUI payloads keep a 0 index.
    if raw[0] ~= nil then
        for i = 0, #raw do
            push(raw[i])
        end
    elseif #raw > 0 then
        for i = 1, #raw do
            push(raw[i])
        end
    else
        for _, row in pairs(raw) do
            push(row)
        end
    end
    return extras
end

local function uniqueId(category, label, requested)
    local base = trim(requested)
    if base == '' then
        base = ('%s_%s'):format(PREFIX[category] or 'item', slug(label))
    else
        base = slug(base)
    end
    if not GetCatalogItem(base) then
        return base
    end
    local i = 2
    while GetCatalogItem(base .. '_' .. i) do
        i = i + 1
    end
    return base .. '_' .. i
end

function Listings.Normalize(payload, existingId)
    if type(payload) ~= 'table' then
        return nil, 'invalid'
    end
    local category = trim(payload.category)
    if not CATEGORIES[category] then
        return nil, 'invalid_category'
    end
    local label = trim(payload.label or payload.name)
    if label == '' then
        return nil, 'invalid_label'
    end
    local price = toInt(payload.price, nil)
    if not price or price < 0 then
        return nil, 'invalid_price'
    end

    local itemName = trim(payload.itemName or payload.item or payload.weapon or '')
    local model = trim(payload.model or '')
    local petModel = trim(payload.petModel or '')
    local image = trim(payload.image or payload.imageUrl or '')
    local count = math.max(1, toInt(payload.count, 1))
    local ammo = toInt(payload.ammo, nil)
    local stock = toInt(payload.stock, nil)
    if stock and stock < 0 then
        stock = nil
    end
    local tier = trim(payload.tier)
    if category ~= 'vehicles' and category ~= 'weapons' then
        tier = nil
    else
        tier = NormalizeTier(tier)
        if not TIERS[tier] then
            tier = 'emerald'
        end
    end

    local extras = parseExtras(payload)

    if category == 'vehicles' and model == '' then
        return nil, 'missing_model'
    end
    if category == 'weapons' and itemName == '' then
        return nil, 'missing_item'
    end
    if category == 'extras' and itemName == '' then
        return nil, 'missing_item'
    end
    if category == 'bundles' and #extras < 2 then
        return nil, 'missing_bundle'
    end
    if category == 'pets' and petModel == '' then
        return nil, 'missing_pet'
    end
    if (category == 'exclusives' or category == 'limited') and model == '' and itemName == '' and petModel == '' then
        return nil, 'missing_item'
    end

    local requested = trim(payload.id or payload.itemId)
    if requested == '' and itemName ~= '' and category ~= 'vehicles' then
        requested = itemName
    end
    local id
    if existingId and existingId ~= '' then
        id = existingId
    elseif requested ~= '' then
        id = slug(requested)
        if GetCatalogItem(id) then
            return nil, 'listing_exists'
        end
    else
        id = uniqueId(category, label, '')
    end
    local item = {
        id = id,
        category = category,
        tier = tier,
        label = label,
        description = trim(payload.description),
        price = price,
        unique = toBool(payload.unique),
        stock = stock,
        image = image ~= '' and image or nil,
        imageKey = trim(payload.imageKey) ~= '' and trim(payload.imageKey) or nil,
        garageId = trim(payload.garageId) ~= '' and trim(payload.garageId) or nil,
        garageType = trim(payload.garageType) ~= '' and trim(payload.garageType) or nil,
        limitedFrom = trim(payload.limitedFrom) ~= '' and trim(payload.limitedFrom) or nil,
        limitedUntil = trim(payload.limitedUntil) ~= '' and trim(payload.limitedUntil) or nil,
    }

    if model ~= '' then
        item.model = model
        if not item.imageKey then
            item.imageKey = model
        end
    end

    if category ~= 'bundles' then
        if category == 'weapons' or (itemName ~= '' and itemName:upper():find('^WEAPON_')) then
            item.weapon = itemName:upper()
            item.item = item.weapon
            item.ammo = ammo
            if not item.imageKey then
                item.imageKey = item.item
            end
        elseif itemName ~= '' then
            item.item = itemName
            if not item.imageKey then
                item.imageKey = itemName
            end
        end
    end

    if category == 'bundles' then
        item.extras = extras
        if extras[1] and not item.imageKey then
            item.imageKey = extras[1].item
        end
    elseif category == 'extras' or (item.item and not item.model and not item.weapon and category ~= 'pets') then
        item.extras = {
            { item = item.item or itemName, count = count },
        }
    end

    if petModel ~= '' then
        item.petModel = petModel
        if not item.imageKey then
            item.imageKey = itemName ~= '' and itemName or id
        end
    end

    if category == 'pets' and item.unique == false then
        item.unique = true
    end

    return item
end

function Listings.FromRow(row)
    if not row then
        return nil
    end
    local extras = {}
    if row.extras and row.extras ~= '' then
        local ok, decoded = pcall(json.decode, row.extras)
        if ok and type(decoded) == 'table' then
            extras = decoded
        end
    end
    local item = {
        id = row.item_id,
        category = row.category,
        tier = row.tier and NormalizeTier(row.tier) or nil,
        label = row.label,
        description = row.description,
        price = tonumber(row.price) or 0,
        image = row.image ~= '' and row.image or nil,
        imageKey = row.image_key ~= '' and row.image_key or nil,
        item = row.item_name ~= '' and row.item_name or nil,
        weapon = row.weapon ~= '' and row.weapon or nil,
        model = row.model ~= '' and row.model or nil,
        petModel = row.pet_model ~= '' and row.pet_model or nil,
        ammo = tonumber(row.ammo),
        unique = tonumber(row.unique_item) == 1,
        stock = tonumber(row.stock),
        limitedFrom = row.limited_from ~= '' and row.limited_from or nil,
        limitedUntil = row.limited_until ~= '' and row.limited_until or nil,
        garageId = row.garage_id ~= '' and row.garage_id or nil,
        garageType = row.garage_type ~= '' and row.garage_type or nil,
        extras = extras,
    }
    if (not item.extras or #item.extras == 0) and item.item and not item.model and not item.weapon and not item.petModel then
        item.extras = { { item = item.item, count = tonumber(row.item_count) or 1 } }
    end
    return item
end

function Listings.Rebuild()
    CatalogReset()
    local rows = DB.GetListings()
    for i = 1, #rows do
        CatalogPut(Listings.FromRow(rows[i]))
    end
end

function Listings.Save(payload, existingId)
    local item, err = Listings.Normalize(payload, existingId)
    if not item then
        return nil, err
    end
    DB.UpsertListing(item, payload.count)
    Listings.Rebuild()
    return GetCatalogItem(item.id)
end

function Listings.Delete(itemId)
    if not itemId or itemId == '' then
        return false
    end
    DB.DeleteListing(itemId)
    Listings.Rebuild()
    return true
end

function Listings.EditorRows()
    local all = CatalogAll()
    local out = {}
    for i = 1, #all do
        local item = all[i]
        out[#out + 1] = {
            id = item.id,
            category = item.category,
            tier = item.tier,
            label = item.label,
            description = item.description,
            price = item.price,
            image = item.image,
            imageKey = item.imageKey,
            item = item.item,
            weapon = item.weapon,
            model = item.model,
            petModel = item.petModel,
            ammo = item.ammo,
            unique = item.unique,
            stock = item.stock,
            limitedFrom = item.limitedFrom,
            limitedUntil = item.limitedUntil,
            garageId = item.garageId,
            garageType = item.garageType,
            extras = item.extras,
            count = item.extras and item.extras[1] and item.extras[1].count or 1,
        }
    end
    return out
end
