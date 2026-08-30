local petPed
local petLabel

local function despawnPet()
    if petPed and DoesEntityExist(petPed) then
        DeleteEntity(petPed)
    end
    petPed = nil
    petLabel = nil
end

local function loadModel(model)
    local hash = type(model) == 'number' and model or joaat(model)
    if not IsModelInCdimage(hash) then
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) and GetGameTimer() < timeout do
        Wait(10)
    end
    if not HasModelLoaded(hash) then
        return nil
    end
    return hash
end

RegisterNetEvent('djfivem-305donator:client:spawnPet', function(model, label)
    despawnPet()
    local hash = loadModel(model)
    if not hash then
        return
    end
    local playerPed = PlayerPedId()
    local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.8, 0.8, 0.0)
    petPed = CreatePed(28, hash, coords.x, coords.y, coords.z, GetEntityHeading(playerPed), true, true)
    petLabel = label
    SetModelAsNoLongerNeeded(hash)
    SetEntityAsMissionEntity(petPed, true, true)
    SetBlockingOfNonTemporaryEvents(petPed, true)
    SetPedCanBeTargetted(petPed, false)
    SetPedFleeAttributes(petPed, 0, false)
    SetPedCombatAttributes(petPed, 17, true)
    SetEntityInvincible(petPed, true)
    TaskFollowToOffsetOfEntity(petPed, playerPed, 0.8, 0.0, 0.0, Config.Pet.speed, -1, Config.Pet.followDistance, true)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(Locale.pet_spawned)
    EndTextCommandThefeedPostTicker(false, true)
end)

RegisterNetEvent('djfivem-305donator:client:despawnPet', function()
    despawnPet()
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(Locale.pet_despawned)
    EndTextCommandThefeedPostTicker(false, true)
end)

CreateThread(function()
    while true do
        Wait(1500)
        if petPed and DoesEntityExist(petPed) then
            local playerPed = PlayerPedId()
            local dist = #(GetEntityCoords(playerPed) - GetEntityCoords(petPed))
            if dist > Config.Pet.warpDistance then
                local coords = GetOffsetFromEntityInWorldCoords(playerPed, 0.6, -0.6, 0.0)
                SetEntityCoords(petPed, coords.x, coords.y, coords.z, false, false, false, false)
            end
            TaskFollowToOffsetOfEntity(petPed, playerPed, 0.8, 0.0, 0.0, Config.Pet.speed, -1, Config.Pet.followDistance, true)
        else
            Wait(2000)
        end
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        despawnPet()
    end
end)

function GetActivePetLabel()
    return petLabel
end
