Config = {}

-- Menu
Config.Command = 'donator'
Config.Keybind = 'F11'
Config.KeybindDescription = 'Open The 305 Donator Store'
Config.CloseKey = 'Escape'

-- Currency
Config.CurrencyName = 'Vice Coins'
Config.CurrencyShort = 'VC'

-- Permissions (ACE + framework groups)
Config.AdminAce = 'donator.admin'
Config.AdminGroups = {
    esx = { 'admin', 'superadmin' },
    qb = { 'god', 'admin' },
}

-- Framework: 'auto' | 'esx' | 'qb' | 'qbx' | 'standalone'
Config.Framework = 'auto'

-- Inventory: 'ox' | 'auto' | 'qb' | 'esx' | 'standalone'
-- This store is built around ox_inventory images, weight, and AddItem/RemoveItem.
Config.Inventory = 'ox'

Config.OxInventory = {
    resource = 'ox_inventory',
    -- Fallback when a Fivemanage URL is not set for an item.
    imagePath = 'nui://ox_inventory/web/images',
    requireCanCarry = true,
    refundIfAddFails = true,
}

--[[
    Fivemanage CDN images for the shop UI and ox_inventory metadata.imageurl.

    1. Upload PNGs/WebPs in the Fivemanage dashboard (vehicles, weapons, extras, bundles, pets).
    2. Paste the folder URL below (everything before the filename).
    3. Name files after the spawn/item key: sultan.webp, weapon_pistol.webp, pet_husky.webp
    4. ox_inventory already allows r2.fivemanage.com and i.fmfile.com in inventory:validhosts.

    You can also paste a full URL on any catalog row as `image = 'https://r2.fivemanage.com/...'`
    or map keys in Config.Images.urls.
]]
Config.Images = {
    provider = 'fivemanage',
    baseUrl = '', -- e.g. https://r2.fivemanage.com/YOUR_TEAM_ID
    extension = 'webp',
    urls = {
        -- sultan = 'https://r2.fivemanage.com/YOUR_TEAM_ID/sultan.webp',
        -- WEAPON_PISTOL = 'https://r2.fivemanage.com/YOUR_TEAM_ID/weapon_pistol.webp',
        -- pet_husky = 'https://r2.fivemanage.com/YOUR_TEAM_ID/pet_husky.webp',
    },
}

-- JG Advanced Garages: purchased vehicles are stored in this garage (in_garage = 1)
Config.JGGarages = {
    resource = 'jg-advancedgarages',
    -- Must match a garage `name` from jg-advancedgarages (getAllGarages). Example: legion
    defaultGarage = 'legion',
    -- Leave air/sea blank to auto-pick the first public garage of that type.
    defaultGarages = {
        car = 'legion',
        air = '',
        sea = '',
    },
    types = {
        car = 'car',
        heli = 'air',
        boat = 'sea',
        sea = 'sea',
        air = 'air',
    },
    fuel = 100,
    engine = 1000,
    body = 1000,
}

-- Fallback garage insert when jg-advancedgarages is not started
Config.Garage = {
    esx = {
        table = 'owned_vehicles',
        stored = 1,
        type = 'car',
    },
    qb = {
        table = 'player_vehicles',
        garage = 'pillboxgarage',
        state = 1,
    },
}

-- Default spawn used for standalone vehicle grants
Config.StandaloneVehicleSpawn = vector4(-44.18, -1097.73, 26.42, 70.0)

-- Pets
Config.Pet = {
    followDistance = 2.4,
    warpDistance = 40.0,
    speed = 8.0,
}

-- Shop rules
Config.PurchaseCooldownMs = 1200
Config.MaxGiftDistance = 12.0
Config.AllowOfflineGifts = true
-- Menu gifts to anyone on the server. Set false to require Config.MaxGiftDistance.
Config.AllowRemoteGifts = true
Config.AllowSelfGift = false
Config.UniqueItemsOnce = true

-- Tebex / console grants (vicegrant, vicepackage, givecoinsid)
Config.Tebex = {
    MaxGrant = 250000,
    GrantCommand = 'vicegrant',
    PackageCommand = 'vicepackage',
}

-- Discord logging (paste webhook URLs — leave blank to disable that channel)
Config.Webhooks = {
    purchases = '',
    coins = '',
    admin = '',
    errors = '',
}

Config.WebhookColor = {
    purchase = 16711807, -- hot pink #FF007F
    coins = 16777215,    -- white
    admin = 11141120,    -- dark red
    error = 0,           -- black
}

Config.ServerName = 'The 305'

-- Shop color theme (config only — no in-UI picker): miami | rebel | crimson | ocean | gold | emerald | violet
Config.Theme = 'miami'

-- Notifications: 'auto' | 'ox' | 'esx' | 'qb' | 'native'
Config.Notify = 'auto'

-- Image helpers
Config.VehicleImage = function(model)
    return ('https://docs.fivem.net/vehicles/%s.webp'):format(model)
end
