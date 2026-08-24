Framework = {
    name = 'standalone',
    inventory = 'standalone',
}

local function hasResource(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local function detectFramework()
    local configured = Config.Framework
    if configured ~= 'auto' then
        return configured
    end
    if hasResource('qbx_core') then
        return 'qbx'
    end
    if hasResource('qb-core') then
        return 'qb'
    end
    if hasResource('es_extended') then
        return 'esx'
    end
    return 'standalone'
end

local function detectInventory()
    local configured = Config.Inventory
    if configured ~= 'auto' then
        return configured
    end
    if hasResource('ox_inventory') then
        return 'ox'
    end
    if hasResource('qb-inventory') or hasResource('lj-inventory') or hasResource('ps-inventory') then
        return 'qb'
    end
    if Framework.name == 'esx' then
        return 'esx'
    end
    return 'standalone'
end

CreateThread(function()
    Wait(500)
    Framework.name = detectFramework()
    Framework.inventory = detectInventory()

    if Framework.name == 'esx' then
        Framework.ESX = exports['es_extended']:getSharedObject()
    elseif Framework.name == 'qb' then
        Framework.QBCore = exports['qb-core']:GetCoreObject()
    elseif Framework.name == 'qbx' then
        Framework.QBCore = exports['qb-core'] and exports['qb-core']:GetCoreObject() or nil
    end

    print(('[dj-donator] Framework: %s | Inventory: %s'):format(Framework.name, Framework.inventory))
end)

function Framework.GetIdentifier(source)
    if Framework.name == 'esx' and Framework.ESX then
        local xPlayer = Framework.ESX.GetPlayerFromId(source)
        if xPlayer then
            return xPlayer.identifier, xPlayer.getName()
        end
    elseif (Framework.name == 'qb' or Framework.name == 'qbx') then
        local player
        if Framework.name == 'qbx' and exports.qbx_core then
            player = exports.qbx_core:GetPlayer(source)
        elseif Framework.QBCore then
            player = Framework.QBCore.Functions.GetPlayer(source)
        end
        if player then
            local cid = player.PlayerData.citizenid
            local name = player.PlayerData.charinfo and ('%s %s'):format(player.PlayerData.charinfo.firstname, player.PlayerData.charinfo.lastname) or GetPlayerName(source)
            return cid, name
        end
    end

    for i = 0, GetNumPlayerIdentifiers(source) - 1 do
        local id = GetPlayerIdentifier(source, i)
        if id and id:find('license:') then
            return id, GetPlayerName(source)
        end
    end
    return GetPlayerIdentifier(source, 0), GetPlayerName(source)
end

function Framework.GetPlayerByIdentifier(identifier)
    local players = GetPlayers()
    for i = 1, #players do
        local src = tonumber(players[i])
        local id = Framework.GetIdentifier(src)
        if id == identifier then
            return src
        end
    end
end

function Framework.IsAdmin(source)
    if source == 0 then
        return true
    end
    if IsPlayerAceAllowed(source, Config.AdminAce) then
        return true
    end
    if Framework.name == 'esx' and Framework.ESX then
        local xPlayer = Framework.ESX.GetPlayerFromId(source)
        if xPlayer then
            local group = xPlayer.getGroup and xPlayer.getGroup()
            for i = 1, #Config.AdminGroups.esx do
                if group == Config.AdminGroups.esx[i] then
                    return true
                end
            end
        end
    elseif Framework.name == 'qb' and Framework.QBCore then
        local player = Framework.QBCore.Functions.GetPlayer(source)
        if player then
            local group = player.PlayerData.group or (Framework.QBCore.Functions.HasPermission and nil)
            if Framework.QBCore.Functions.HasPermission then
                for i = 1, #Config.AdminGroups.qb do
                    if Framework.QBCore.Functions.HasPermission(source, Config.AdminGroups.qb[i]) then
                        return true
                    end
                end
            end
            for i = 1, #Config.AdminGroups.qb do
                if group == Config.AdminGroups.qb[i] then
                    return true
                end
            end
        end
    elseif Framework.name == 'qbx' and exports.qbx_core then
        for i = 1, #Config.AdminGroups.qb do
            if exports.qbx_core:HasPermission(source, Config.AdminGroups.qb[i]) then
                return true
            end
        end
    end
    return false
end

function Framework.Notify(source, message, nType)
    nType = nType or 'inform'
    local mode = Config.Notify
    if mode == 'auto' then
        if GetResourceState('ox_lib') == 'started' then
            mode = 'ox'
        elseif Framework.name == 'esx' then
            mode = 'esx'
        elseif Framework.name == 'qb' or Framework.name == 'qbx' then
            mode = 'qb'
        else
            mode = 'native'
        end
    end

    if mode == 'ox' then
        TriggerClientEvent('ox_lib:notify', source, { title = Config.ServerName, description = message, type = nType })
    elseif mode == 'esx' then
        TriggerClientEvent('esx:showNotification', source, message)
    elseif mode == 'qb' then
        TriggerClientEvent('QBCore:Notify', source, message, nType == 'error' and 'error' or 'success')
    else
        TriggerClientEvent('dj-donator:client:notify', source, message, nType)
    end
end

function Framework.AddItem(source, itemName, count, metadata)
    count = count or 1
    if Framework.inventory == 'ox' then
        return exports.ox_inventory:AddItem(source, itemName, count, metadata)
    elseif Framework.inventory == 'qb' then
        local player
        if Framework.name == 'qbx' and exports.qbx_core then
            player = exports.qbx_core:GetPlayer(source)
        else
            player = Framework.QBCore and Framework.QBCore.Functions.GetPlayer(source)
        end
        if player then
            return player.Functions.AddItem(itemName, count, false, metadata)
        end
    elseif Framework.inventory == 'esx' and Framework.ESX then
        local xPlayer = Framework.ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.addInventoryItem(itemName, count)
            return true
        end
    else
        TriggerClientEvent('dj-donator:client:giveWeaponNative', source, itemName, count)
        return true
    end
    return false
end

function Framework.GiveWeapon(source, weaponName, ammo, itemName)
    ammo = ammo or 0
    if Framework.inventory == 'ox' then
        return exports.ox_inventory:AddItem(source, itemName or weaponName:lower(), 1, { ammo = ammo })
    elseif Framework.inventory == 'qb' then
        local player
        if Framework.name == 'qbx' and exports.qbx_core then
            player = exports.qbx_core:GetPlayer(source)
        else
            player = Framework.QBCore and Framework.QBCore.Functions.GetPlayer(source)
        end
        if player then
            player.Functions.AddItem(itemName or weaponName:lower(), 1)
            TriggerClientEvent('inventory:client:ItemBox', source, { name = itemName or weaponName:lower() }, 'add')
            return true
        end
    elseif Framework.inventory == 'esx' and Framework.ESX then
        local xPlayer = Framework.ESX.GetPlayerFromId(source)
        if xPlayer then
            xPlayer.addWeapon(weaponName, ammo)
            return true
        end
    else
        TriggerClientEvent('dj-donator:client:giveWeaponNative', source, weaponName, ammo)
        return true
    end
    return false
end

local function randomPlate()
    local chars = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789'
    local plate = 'RC'
    for _ = 1, 6 do
        local idx = math.random(1, #chars)
        plate = plate .. chars:sub(idx, idx)
    end
    return plate
end

function Framework.GiveVehicle(source, identifier, item)
    local plate = randomPlate()
    local model = item.model
    local props = json.encode({
        model = joaat(model),
        plate = plate,
        fuelLevel = 100.0,
    })
    local garageType = item.garageType or 'car'

    if Framework.name == 'esx' then
        MySQL.insert.await(
            'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)',
            { identifier, plate, props, garageType, Config.Garage.esx.stored }
        )
        return plate
    elseif Framework.name == 'qb' or Framework.name == 'qbx' then
        local license = identifier
        if GetPlayerIdentifierByType then
            license = GetPlayerIdentifierByType(source, 'license') or identifier
        end
        local garage = Config.Garage.qb.garage
        MySQL.insert.await(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            { license, identifier, model, joaat(model), props, plate, garage, Config.Garage.qb.state }
        )
        return plate
    else
        TriggerClientEvent('dj-donator:client:spawnVehicle', source, model, plate)
        return plate
    end
end
