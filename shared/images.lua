Images = {}

local function trimSlash(url)
    return (url or ''):gsub('/$', '')
end

local function isAutoFallback(url)
    if type(url) ~= 'string' then
        return false
    end
    return url:find('docs.fivem.net', 1, true) ~= nil
        or url:find('nui://ox_inventory/', 1, true) ~= nil
        or url:find('raw.githubusercontent.com/overextended/ox_inventory', 1, true) ~= nil
end

function Images.IsUrl(value)
    return type(value) == 'string' and value:find('^https?://') ~= nil
end

function Images.IsConfigured()
    local cfg = Config.Images or {}
    local base = cfg.baseUrl or ''
    return base ~= '' and not base:find('YOUR_TEAM', 1, true) and not base:find('PASTE_', 1, true)
end

-- Filename key on Fivemanage: sultan.webp, weapon_pistol.webp, armour.webp, pet_husky.webp
function Images.Key(itemOrKey)
    if type(itemOrKey) == 'table' then
        if itemOrKey.imageKey and itemOrKey.imageKey ~= '' then
            return itemOrKey.imageKey
        end
        if itemOrKey.model then
            return itemOrKey.model
        end
        if itemOrKey.item then
            return itemOrKey.item
        end
        if itemOrKey.weapon then
            return itemOrKey.weapon
        end
        if itemOrKey.extras and itemOrKey.extras[1] and itemOrKey.extras[1].item then
            return itemOrKey.extras[1].item
        end
        return itemOrKey.id
    end
    return itemOrKey
end

function Images.FileName(key)
    if not key then
        return nil
    end
    return tostring(key):lower()
end

function Images.FromMap(key)
    local urls = Config.Images and Config.Images.urls or {}
    if not key then
        return nil
    end
    local file = Images.FileName(key)
    return urls[key] or urls[tostring(key):lower()] or urls[tostring(key):upper()] or (file and urls[file])
end

function Images.Build(key)
    if not key or not Images.IsConfigured() then
        return nil
    end
    local ext = Config.Images.extension or 'webp'
    return ('%s/%s.%s'):format(trimSlash(Config.Images.baseUrl), Images.FileName(key), ext)
end

-- Prefer Config.Images.urls, then an explicit catalog URL, then Fivemanage baseUrl + key.
-- docs.fivem.net / ox nui paths are treated as fallbacks so a configured Fivemanage folder wins.
function Images.Resolve(itemOrKey, fallback)
    local item = type(itemOrKey) == 'table' and itemOrKey or nil
    local key = Images.Key(itemOrKey)

    local mapped = Images.FromMap(key)
    if mapped then
        return mapped
    end
    if item then
        mapped = Images.FromMap(item.id) or Images.FromMap(item.model) or Images.FromMap(item.item) or Images.FromMap(item.weapon)
        if mapped then
            return mapped
        end
    end

    local explicit = item and item.image
    if Images.IsUrl(explicit) and not isAutoFallback(explicit) then
        return explicit
    end
    if Images.IsUrl(itemOrKey) and not isAutoFallback(itemOrKey) then
        return itemOrKey
    end

    local built = Images.Build(key)
    if built then
        return built
    end

    if Images.IsUrl(explicit) then
        return explicit
    end
    if Images.IsUrl(itemOrKey) then
        return itemOrKey
    end
    return fallback
end

function Images.ForGrant(itemName, catalogItem)
    return Images.Resolve(itemName) or (catalogItem and Images.Resolve(catalogItem)) or nil
end
