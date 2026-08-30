JGGarage = {
    ready = false,
}

local function resourceName()
    return (Config.JGGarages and Config.JGGarages.resource) or 'jg-advancedgarages'
end

local function started()
    local state = GetResourceState(resourceName())
    return state == 'started' or state == 'starting'
end

function JGGarage.Ready()
    return started()
end

local function mapType(garageType)
    local map = (Config.JGGarages and Config.JGGarages.types) or {}
    return map[garageType or 'car'] or garageType or 'car'
end

local function preferredName(vehType)
    local cfg = Config.JGGarages or {}
    local typed = cfg.defaultGarages and cfg.defaultGarages[vehType]
    if type(typed) == 'string' and typed ~= '' then
        return typed
    end
    return cfg.defaultGarage or 'legion'
end

local function garageVehicle(g)
    return g.vehicle or g.vehicleType
end

local function matchesType(g, vehType)
    local v = garageVehicle(g)
    if not v then
        return vehType == 'car'
    end
    return v == vehType
end

function JGGarage.ResolveGarage(preferred, vehType)
    vehType = mapType(vehType)
    local fallback = preferred or preferredName(vehType)
    if not JGGarage.Ready() then
        return fallback, vehType
    end

    local ok, garages = pcall(function()
        return exports[resourceName()]:getAllGarages()
    end)
    if not ok or type(garages) ~= 'table' then
        return fallback, vehType
    end

    local named
    for i = 1, #garages do
        local g = garages[i]
        if g.name == fallback or g.label == fallback then
            named = g
            if matchesType(g, vehType) then
                return g.name, garageVehicle(g) or vehType
            end
        end
    end

    for i = 1, #garages do
        local g = garages[i]
        local public = g.type == 'public' or g.type == nil
        if public and matchesType(g, vehType) then
            return g.name, vehType
        end
    end

    for i = 1, #garages do
        local g = garages[i]
        if matchesType(g, vehType) then
            return g.name, vehType
        end
    end

    if named then
        return named.name, garageVehicle(named) or vehType
    end
    if garages[1] then
        return garages[1].name, garageVehicle(garages[1]) or vehType
    end
    return fallback, vehType
end

local function propsJson(model, plate, fuel, engine, body)
    return json.encode({
        model = joaat(model),
        plate = plate,
        fuelLevel = fuel or 100.0,
        engineHealth = engine or 1000.0,
        bodyHealth = body or 1000.0,
    })
end

local function tryUpdate(query, params)
    local ok, err = pcall(function()
        MySQL.update.await(query, params)
    end)
    if not ok then
        print(('[djfivem-305donator] JG garage column update skipped: %s'):format(tostring(err)))
    end
    return ok
end

function JGGarage.Give(source, identifier, item, plate)
    local model = item.model
    local garageId, vehType = JGGarage.ResolveGarage(item.garageId or item.garage, item.garageType or 'car')
    local fuel = (Config.JGGarages and Config.JGGarages.fuel) or 100
    local engine = (Config.JGGarages and Config.JGGarages.engine) or 1000
    local body = (Config.JGGarages and Config.JGGarages.body) or 1000
    local props = propsJson(model, plate, fuel, engine, body)

    if Framework.name == 'esx' then
        MySQL.insert.await(
            'INSERT INTO owned_vehicles (owner, plate, vehicle, type, stored) VALUES (?, ?, ?, ?, ?)',
            { identifier, plate, props, vehType, 1 }
        )
        tryUpdate(
            'UPDATE owned_vehicles SET in_garage = 1, garage_id = ?, stored = 1, impound = 0 WHERE plate = ?',
            { garageId, plate }
        )
        tryUpdate(
            'UPDATE owned_vehicles SET parking = ?, garage = ? WHERE plate = ?',
            { garageId, garageId, plate }
        )
        tryUpdate(
            'UPDATE owned_vehicles SET type = ? WHERE plate = ?',
            { vehType, plate }
        )
    else
        local license = identifier
        if source and GetPlayerIdentifierByType then
            license = GetPlayerIdentifierByType(source, 'license') or identifier
        end
        MySQL.insert.await(
            'INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, garage, state) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
            { license, identifier, model, joaat(model), props, plate, garageId, 1 }
        )
        tryUpdate(
            'UPDATE player_vehicles SET in_garage = 1, garage_id = ?, garage = ?, state = 1, fuel = ?, engine = ?, body = ?, impound = 0 WHERE plate = ?',
            { garageId, garageId, fuel, engine, body, plate }
        )
        tryUpdate(
            'UPDATE player_vehicles SET type = ? WHERE plate = ?',
            { vehType, plate }
        )
    end

    print(('[djfivem-305donator] Stored %s (%s) in JG garage "%s" (%s) for %s'):format(model, plate, garageId, vehType, identifier))
    return plate, garageId
end

CreateThread(function()
    local deadline = GetGameTimer() + 20000
    while GetGameTimer() < deadline and not started() do
        Wait(200)
    end
    JGGarage.ready = started()
    if JGGarage.ready then
        print('[djfivem-305donator] Linked with jg-advancedgarages. Purchased vehicles go into the configured garage.')
    else
        print('[djfivem-305donator] jg-advancedgarages not started; vehicles use the fallback garage insert.')
    end
end)
