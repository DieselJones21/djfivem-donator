local open = false
local lastCoins

local function nui(action, data)
    SendNUIMessage({ action = action, data = data })
end

local function setFocus(state)
    SetNuiFocus(state, state)
    SetNuiFocusKeepInput(false)
end

local function closeMenu()
    if not open then
        return
    end
    open = false
    setFocus(false)
    nui('close')
end

local function openMenu()
    if open then
        closeMenu()
        return
    end
    local result = DonatorCallback('open')
    if not result or not result.ok then
        return
    end
    open = true
    lastCoins = result.player and result.player.coins
    setFocus(true)
    nui('open', result)
end

RegisterCommand(Config.Command, function()
    openMenu()
end, false)

RegisterKeyMapping(Config.Command, Config.KeybindDescription, 'keyboard', Config.Keybind)

RegisterNUICallback('close', function(_, cb)
    closeMenu()
    cb({ ok = true })
end)

RegisterNUICallback('purchase', function(data, cb)
    cb(DonatorCallback('purchase', data) or { ok = false })
end)

RegisterNUICallback('gift', function(data, cb)
    cb(DonatorCallback('gift', data) or { ok = false })
end)

RegisterNUICallback('redeem', function(data, cb)
    cb(DonatorCallback('redeem', data) or { ok = false })
end)

RegisterNUICallback('spawnPet', function(data, cb)
    cb(DonatorCallback('spawnPet', data) or { ok = false })
end)

RegisterNUICallback('despawnPet', function(_, cb)
    cb(DonatorCallback('despawnPet') or { ok = false })
end)

RegisterNUICallback('adminGive', function(data, cb)
    cb(DonatorCallback('adminGive', data) or { ok = false })
end)

RegisterNUICallback('adminRemove', function(data, cb)
    cb(DonatorCallback('adminRemove', data) or { ok = false })
end)

RegisterNUICallback('adminSet', function(data, cb)
    cb(DonatorCallback('adminSet', data) or { ok = false })
end)

RegisterNUICallback('adminRefresh', function(_, cb)
    cb(DonatorCallback('adminRefresh') or { ok = false })
end)

RegisterNUICallback('adminCreateCode', function(data, cb)
    cb(DonatorCallback('adminCreateCode', data) or { ok = false })
end)

RegisterNUICallback('adminLookup', function(data, cb)
    cb(DonatorCallback('adminLookup', data) or { ok = false })
end)

RegisterNUICallback('adminRefund', function(data, cb)
    cb(DonatorCallback('adminRefund', data) or { ok = false })
end)

RegisterNUICallback('adminSaveListing', function(data, cb)
    cb(DonatorCallback('adminSaveListing', data) or { ok = false })
end)

RegisterNUICallback('adminDeleteListing', function(data, cb)
    cb(DonatorCallback('adminDeleteListing', data) or { ok = false })
end)

RegisterNetEvent('djfivem-305donator:client:notify', function(message, nType)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(message)
    EndTextCommandThefeedPostTicker(nType == 'error', true)
    nui('toast', { message = message, type = nType or 'inform' })
end)

RegisterNetEvent('djfivem-305donator:client:coinsUpdated', function(coins)
    lastCoins = coins
    nui('coins', { coins = coins })
end)

RegisterNetEvent('djfivem-305donator:client:ownedPetsUpdated', function()
    if open then
        local result = DonatorCallback('open')
        if result and result.ok then
            nui('sync', result)
        end
    end
end)

RegisterNetEvent('djfivem-305donator:client:giveWeaponNative', function(weaponName, ammo)
    local ped = PlayerPedId()
    if type(weaponName) == 'string' and weaponName:find('WEAPON_') then
        GiveWeaponToPed(ped, joaat(weaponName), ammo or 0, false, true)
    end
end)

RegisterNetEvent('djfivem-305donator:client:spawnVehicle', function(model, plate)
    local hash = type(model) == 'number' and model or joaat(model)
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(hash) then
        return
    end
    local spawn = Config.StandaloneVehicleSpawn
    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    SetVehicleNumberPlateText(veh, plate or 'REBEL')
    SetPedIntoVehicle(PlayerPedId(), veh, -1)
    SetVehicleOnGroundProperly(veh)
    SetEntityAsMissionEntity(veh, true, true)
    SetModelAsNoLongerNeeded(hash)
end)

CreateThread(function()
    TriggerServerEvent('djfivem-305donator:server:playerReady')
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() and open then
        setFocus(false)
    end
end)
