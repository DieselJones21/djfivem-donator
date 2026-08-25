--[[
    Live shop catalog. Built-in listings are empty on purpose — admins add
    vehicles, weapons, extras, exclusives, limited drops, and pets in-game
    from the Admin tab (stored in dj_donator_listings).
]]

function CatalogReset()
    Catalog = {
        vehicles = { bronze = {}, silver = {}, gold = {} },
        weapons = { bronze = {}, silver = {}, gold = {} },
        extras = {},
        exclusives = {},
        limited = {},
        pets = {},
    }
end

CatalogReset()

function CatalogPut(item)
    if not item or not item.id then
        return
    end
    local category = item.category or 'extras'
    if category == 'vehicles' then
        local tier = item.tier or 'bronze'
        if not Catalog.vehicles[tier] then
            Catalog.vehicles[tier] = {}
        end
        Catalog.vehicles[tier][#Catalog.vehicles[tier] + 1] = item
    elseif category == 'weapons' then
        local tier = item.tier or 'bronze'
        if not Catalog.weapons[tier] then
            Catalog.weapons[tier] = {}
        end
        Catalog.weapons[tier][#Catalog.weapons[tier] + 1] = item
    elseif Catalog[category] then
        Catalog[category][#Catalog[category] + 1] = item
    else
        Catalog.extras[#Catalog.extras + 1] = item
    end
end

function CatalogAll()
    local out = {}
    local function take(list, category, tier)
        if not list then
            return
        end
        for i = 1, #list do
            local copy = {}
            for k, v in pairs(list[i]) do
                copy[k] = v
            end
            copy.category = copy.category or category
            copy.tier = copy.tier or tier
            out[#out + 1] = copy
        end
    end
    for _, tier in ipairs({ 'bronze', 'silver', 'gold' }) do
        take(Catalog.vehicles[tier], 'vehicles', tier)
        take(Catalog.weapons[tier], 'weapons', tier)
    end
    take(Catalog.extras, 'extras')
    take(Catalog.exclusives, 'exclusives')
    take(Catalog.limited, 'limited')
    take(Catalog.pets, 'pets')
    return out
end

function GetCatalogItem(itemId)
    if not itemId then
        return nil
    end
    local all = CatalogAll()
    for i = 1, #all do
        if all[i].id == itemId then
            return all[i]
        end
    end
end
