Config = {}

-- Menu
Config.Command = 'donator'
Config.Keybind = 'F7'
Config.KeybindDescription = 'Open Rebel Donator Store'
Config.CloseKey = 'Escape'

-- Currency
Config.CurrencyName = 'Rebel Coins'
Config.CurrencyShort = 'RC'

-- Permissions (ACE + framework groups)
Config.AdminAce = 'donator.admin'
Config.AdminGroups = {
    esx = { 'admin', 'superadmin' },
    qb = { 'god', 'admin' },
}

-- Framework: 'auto' | 'esx' | 'qb' | 'qbx' | 'standalone'
Config.Framework = 'auto'

-- Inventory: 'auto' | 'ox' | 'qb' | 'esx' | 'standalone'
Config.Inventory = 'auto'

-- Garage table mapping used when granting vehicles
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
Config.AllowSelfGift = false
Config.UniqueItemsOnce = true

-- Discord logging (paste webhook URLs — leave blank to disable that channel)
Config.Webhooks = {
    purchases = '',
    coins = '',
    admin = '',
    errors = '',
}

Config.WebhookColor = {
    purchase = 13697070, -- red
    coins = 16777215,    -- white
    admin = 11141120,    -- dark red
    error = 0,           -- black
}

Config.ServerName = 'Rebel RP'

-- Notifications: 'auto' | 'ox' | 'esx' | 'qb' | 'native'
Config.Notify = 'auto'

-- Image helpers
Config.VehicleImage = function(model)
    return ('https://docs.fivem.net/vehicles/%s.webp'):format(model)
end
