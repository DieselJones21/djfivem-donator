local cooldowns = {}

local function nowUtc()
    return os.time(os.date('!*t'))
end

local function parseIso(str)
    if type(str) ~= 'string' or str == '' then
        return nil
    end
    local y, m, d, h, min, s = str:match('^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)')
    if not y then
        return nil
    end
    return os.time({
        year = tonumber(y),
        month = tonumber(m),
        day = tonumber(d),
        hour = tonumber(h),
        min = tonumber(min),
        sec = tonumber(s),
        isdst = false,
    })
end

local function limitedState(item)
    local from = parseIso(item.limitedFrom)
    local untilTime = parseIso(item.limitedUntil)
    local now = nowUtc()
    if from and now < from then
        return false, 'not_started', from, untilTime
    end
    if untilTime and now > untilTime then
        return false, 'expired', from, untilTime
    end
    return true, 'active', from, untilTime
end

local function remainingStock(item)
    if not item.stock then
        return nil
    end
    return math.max(0, item.stock - DB.CountItemSold(item.id))
end

local function publicItem(item)
    local active, reason, from, untilTime = true, nil, nil, nil
    if item.limitedFrom or item.limitedUntil then
        active, reason, from, untilTime = limitedState(item)
    end
    local pub = {
        id = item.id,
        label = item.label,
        description = item.description,
        price = item.price,
        category = item.category,
        tier = item.tier,
        model = item.model,
        weapon = item.weapon,
        petModel = item.petModel,
        unique = item.unique and true or false,
        stock = item.stock,
        remaining = remainingStock(item),
        image = item.image,
        limitedFrom = item.limitedFrom,
        limitedUntil = item.limitedUntil,
        limitedActive = active,
        limitedReason = reason,
        limitedFromTs = from,
        limitedUntilTs = untilTime,
        extras = item.extras,
        ammo = item.ammo,
        garageId = item.garageId,
        garageType = item.garageType,
    }
    pub.image = Images.Resolve(item, pub.image)
    pub.imageKey = item.imageKey or Images.Key(item)
    if OxInv and OxInv.Ready() then
        OxInv.DecoratePublic(pub, item)
    end
    return pub
end

local function publicCatalog()
    local out = {
        vehicles = { bronze = {}, silver = {}, gold = {} },
        weapons = { bronze = {}, silver = {}, gold = {} },
        extras = {},
        exclusives = {},
        limited = {},
        pets = {},
    }

    for tier, list in pairs(Catalog.vehicles) do
        for i = 1, #list do
            local item = list[i]
            item.category = 'vehicles'
            item.tier = tier
            out.vehicles[tier][#out.vehicles[tier] + 1] = publicItem(item)
        end
    end
    for tier, list in pairs(Catalog.weapons) do
        for i = 1, #list do
            local item = list[i]
            item.category = 'weapons'
            item.tier = tier
            out.weapons[tier][#out.weapons[tier] + 1] = publicItem(item)
        end
    end

    local function fill(src, dest, category)
        for i = 1, #src do
            src[i].category = category
            dest[#dest + 1] = publicItem(src[i])
        end
    end

    fill(Catalog.extras, out.extras, 'extras')
    fill(Catalog.exclusives, out.exclusives, 'exclusives')
    fill(Catalog.limited, out.limited, 'limited')
    fill(Catalog.pets, out.pets, 'pets')
    return out
end

local function isOnCooldown(source)
    local last = cooldowns[source]
    if last and (GetGameTimer() - last) < Config.PurchaseCooldownMs then
        return true
    end
    cooldowns[source] = GetGameTimer()
    return false
end

local function applyInventoryGrant(targetSource, item)
    if not targetSource then
        return false, 'offline'
    end
    local grants = OxInv and OxInv.GrantsFor(item) or {}
    if #grants == 0 then
        return true, {}
    end
    if not OxInv or not OxInv.Ready() then
        return false, 'ox_missing'
    end
    return OxInv.GiveGrants(targetSource, grants)
end

local function grantItem(targetSource, identifier, item)
    local data = {
        model = item.model,
        weapon = item.weapon,
        petModel = item.petModel,
        extras = item.extras,
        plate = nil,
        pending = false,
    }

    if item.model then
        if not targetSource and Framework.name == 'standalone' then
            data.pending = true
        else
            local plate, garageId = Framework.GiveVehicle(targetSource, identifier, item)
            data.plate = plate
            data.garageId = garageId
        end
    elseif item.weapon or item.extras or item.item or item.petModel then
        if targetSource then
            local ok, added = applyInventoryGrant(targetSource, item)
            if not ok then
                data.grantFailed = added or 'inventory_full'
                return data
            end
            data.oxAdded = added
        else
            data.pending = true
        end
    end

    DB.InsertOwned(identifier, item, data)
    return data
end

local function flushPending(source)
    local identifier = Framework.GetIdentifier(source)
    if not identifier then
        return
    end
    local owned = DB.GetOwned(identifier)
    for i = 1, #owned do
        local row = owned[i]
        local data = json.decode(row.data or '{}') or {}
        if data.pending then
            local item = GetCatalogItem(row.item_id)
            if item then
                local ok = applyInventoryGrant(source, item)
                if ok then
                    data.pending = false
                    MySQL.update.await('UPDATE dj_donator_owned SET data = ? WHERE id = ?', { json.encode(data), row.id })
                end
            end
        end
    end
end

local function playerSnapshot(source)
    local identifier, name = Framework.GetIdentifier(source)
    if not identifier then
        return nil
    end
    local coins = DB.GetCoins(identifier)
    local owned = DB.GetOwned(identifier)
    local history = DB.GetPurchases(identifier, 30)
    local series = DB.GetSpendSeries(identifier)
    return {
        identifier = identifier,
        name = name or GetPlayerName(source),
        serverId = source,
        coins = coins.coins,
        lifetimeSpent = coins.lifetime_spent,
        lifetimeGranted = coins.lifetime_granted,
        owned = owned,
        history = history,
        series = series,
        isAdmin = Framework.IsAdmin(source),
        ox = OxInv and OxInv.PlayerInfo(source) or nil,
    }
end

local function onlinePlayers()
    local list = {}
    local players = GetPlayers()
    for i = 1, #players do
        local src = tonumber(players[i])
        local identifier, name = Framework.GetIdentifier(src)
        if identifier then
            local coins = DB.GetCoins(identifier)
            list[#list + 1] = {
                id = src,
                name = name or GetPlayerName(src),
                identifier = identifier,
                coins = coins.coins,
            }
        end
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function canBuy(identifier, item)
    if not item then
        return false, 'invalid'
    end
    if item.limitedFrom or item.limitedUntil then
        local active, reason = limitedState(item)
        if not active then
            return false, reason
        end
    end
    local remaining = remainingStock(item)
    if remaining and remaining <= 0 then
        return false, 'out_of_stock'
    end
    if item.unique and Config.UniqueItemsOnce and DB.OwnsUnique(identifier, item.id) then
        return false, 'already_owned'
    end
    return true
end

local function inventoryGate(source, item)
    local grants = OxInv and OxInv.GrantsFor(item) or {}
    if #grants == 0 then
        return true
    end
    if not source then
        return true
    end
    if not OxInv or not OxInv.Ready() then
        return false, 'ox_missing', Locale.ox_missing
    end
    local can, err, detail = OxInv.CanCarryGrants(source, grants)
    if not can then
        local msg = err == 'invalid_item' and Locale.invalid_ox_item or Locale.cannot_carry
        if detail then
            msg = ('%s (%s)'):format(msg, detail)
        end
        return false, err, msg
    end
    return true
end

local function resolveTarget(payload)
    if payload.targetId then
        local src = tonumber(payload.targetId)
        if src and GetPlayerName(src) then
            local identifier, name = Framework.GetIdentifier(src)
            return src, identifier, name
        end
    end
    if payload.identifier and payload.identifier ~= '' then
        local src = Framework.GetPlayerByIdentifier(payload.identifier)
        return src, payload.identifier, payload.targetName
    end
end

RegisterDonatorCallback('open', function(source)
    local snap = playerSnapshot(source)
    if not snap then
        return { ok = false, error = 'invalid_player' }
    end
    local everyone = onlinePlayers()
    local admin = {}
    if snap.isAdmin then
        admin.players = everyone
        admin.logs = DB.GetLogs(40)
        admin.codes = DB.ListCodes()
    end
    local giftPlayers = {}
    for i = 1, #everyone do
        giftPlayers[#giftPlayers + 1] = { id = everyone[i].id, name = everyone[i].name }
    end
    return {
        ok = true,
        player = snap,
        catalog = publicCatalog(),
        admin = admin,
        players = giftPlayers,
        locale = Locale,
        currency = { name = Config.CurrencyName, short = Config.CurrencyShort },
        serverName = Config.ServerName,
        keybind = Config.Keybind,
    }
end)

RegisterDonatorCallback('purchase', function(source, payload)
    if isOnCooldown(source) then
        return { ok = false, error = 'cooldown', message = Locale.cooldown }
    end
    local identifier, name = Framework.GetIdentifier(source)
    local item = GetCatalogItem(payload.itemId)
    if not identifier or not item then
        return { ok = false, error = 'invalid', message = 'Invalid item.' }
    end
    local ok, reason = canBuy(identifier, item)
    if not ok then
        local messages = {
            expired = Locale.expired,
            not_started = Locale.not_started,
            out_of_stock = Locale.out_of_stock,
            already_owned = Locale.already_owned,
        }
        return { ok = false, error = reason, message = messages[reason] or 'Cannot buy this item.' }
    end
    local invOk, invErr, invMsg = inventoryGate(source, item)
    if not invOk then
        return { ok = false, error = invErr, message = invMsg }
    end
    if not DB.TrySpend(identifier, item.price) then
        return { ok = false, error = 'not_enough', message = Locale.not_enough }
    end

    local data = grantItem(source, identifier, item)
    if data.grantFailed then
        DB.AddCoins(identifier, item.price)
        return { ok = false, error = 'inventory_full', message = Locale.inventory_full }
    end
    DB.InsertPurchase(identifier, name, item, item.price, 1, nil)
    DB.InsertLog(identifier, name, identifier, name, 'purchase', {
        item = item.id,
        price = item.price,
        plate = data.plate,
    })
    Webhooks.Purchase(name, identifier, item, item.price)
    Framework.Notify(source, Locale.purchased, 'success')

    if item.model then
        Framework.Notify(source, Locale.vehicle_granted, 'success')
    elseif item.weapon then
        Framework.Notify(source, Locale.weapon_granted, 'success')
    elseif item.petModel then
        TriggerClientEvent('dj-donator:client:ownedPetsUpdated', source)
    else
        Framework.Notify(source, Locale.item_granted, 'success')
    end

    return { ok = true, player = playerSnapshot(source), granted = data }
end)

RegisterDonatorCallback('gift', function(source, payload)
    if isOnCooldown(source) then
        return { ok = false, error = 'cooldown', message = Locale.cooldown }
    end
    local buyerId, buyerName = Framework.GetIdentifier(source)
    local item = GetCatalogItem(payload.itemId)
    if not buyerId or not item then
        return { ok = false, error = 'invalid', message = 'Invalid item.' }
    end
    local targetSource, targetIdentifier, targetName = resolveTarget(payload)
    if not targetIdentifier then
        return { ok = false, error = 'invalid_player', message = Locale.invalid_player }
    end
    if not Config.AllowSelfGift and targetIdentifier == buyerId then
        return { ok = false, error = 'invalid_player', message = 'You cannot gift this to yourself.' }
    end
    if not targetSource and not Config.AllowOfflineGifts then
        return { ok = false, error = 'invalid_player', message = 'That player must be online.' }
    end
    if targetSource and Config.MaxGiftDistance and Config.MaxGiftDistance > 0 then
        local buyerPed = GetPlayerPed(source)
        local targetPed = GetPlayerPed(targetSource)
        if buyerPed ~= 0 and targetPed ~= 0 then
            local b = GetEntityCoords(buyerPed)
            local t = GetEntityCoords(targetPed)
            if #(b - t) > Config.MaxGiftDistance then
                -- Online list gifts from the menu are allowed across the server;
                -- distance only applies if both peds exist and payload.nearby is set.
                if payload.nearby then
                    return { ok = false, error = 'distance', message = 'That player is too far away.' }
                end
            end
        end
    end

    local ok, reason = canBuy(targetIdentifier, item)
    if not ok then
        return { ok = false, error = reason, message = Locale[reason] or 'Cannot gift this item.' }
    end
    local invOk, invErr, invMsg = inventoryGate(targetSource, item)
    if not invOk then
        return { ok = false, error = invErr, message = invMsg }
    end
    if not DB.TrySpend(buyerId, item.price) then
        return { ok = false, error = 'not_enough', message = Locale.not_enough }
    end

    local data = grantItem(targetSource, targetIdentifier, item)
    if data.grantFailed then
        DB.AddCoins(buyerId, item.price)
        return { ok = false, error = 'inventory_full', message = Locale.inventory_full }
    end
    DB.InsertPurchase(buyerId, buyerName, item, item.price, 1, targetIdentifier)
    DB.InsertLog(buyerId, buyerName, targetIdentifier, targetName, 'gift', {
        item = item.id,
        price = item.price,
    })
    Webhooks.Purchase(buyerName, buyerId, item, item.price, ('%s (%s)'):format(targetName or 'Unknown', targetIdentifier))
    Framework.Notify(source, Locale.gifted, 'success')
    if targetSource then
        Framework.Notify(targetSource, Locale.received_gift .. ' (' .. item.label .. ')', 'success')
        TriggerClientEvent('dj-donator:client:ownedPetsUpdated', targetSource)
    end
    return { ok = true, player = playerSnapshot(source), granted = data }
end)

RegisterDonatorCallback('redeem', function(source, payload)
    local identifier, name = Framework.GetIdentifier(source)
    local code = payload.code and tostring(payload.code):gsub('%s+', ''):upper() or ''
    if code == '' then
        return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
    end
    local row = DB.GetCode(code)
    if not row then
        return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
    end
    if row.max_uses and row.uses >= row.max_uses then
        return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
    end
    if row.expires_at and row.expires_at ~= '' then
        -- MySQL datetime compared lexicographically as UTC-ish string
        local expires = parseIso(tostring(row.expires_at):gsub(' ', 'T') .. 'Z')
        if expires and nowUtc() > expires then
            return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
        end
    end
    if DB.HasRedeemed(row.id, identifier) then
        return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
    end
    if row.item_id and row.item_id ~= '' then
        local item = GetCatalogItem(row.item_id)
        if item then
            local invOk, invErr, invMsg = inventoryGate(source, item)
            if not invOk then
                return { ok = false, error = invErr, message = invMsg }
            end
        end
    end

    DB.RedeemCode(row.id, identifier)
    if row.coins and row.coins > 0 then
        DB.AddCoins(identifier, row.coins)
    end
    if row.item_id and row.item_id ~= '' then
        local item = GetCatalogItem(row.item_id)
        if item then
            local granted = grantItem(source, identifier, item)
            if granted.grantFailed then
                return { ok = false, error = 'inventory_full', message = Locale.inventory_full }
            end
        end
    end
    DB.InsertLog(identifier, name, identifier, name, 'redeem', { code = code, coins = row.coins, item = row.item_id })
    Webhooks.Admin(name, identifier, 'redeem', ('Redeemed code %s for %s RC'):format(code, tostring(row.coins or 0)))
    Framework.Notify(source, Locale.redeemed, 'success')
    return { ok = true, player = playerSnapshot(source) }
end)

RegisterDonatorCallback('spawnPet', function(source, payload)
    local identifier = Framework.GetIdentifier(source)
    local owned = DB.GetOwned(identifier)
    local found
    for i = 1, #owned do
        if owned[i].item_id == payload.itemId and owned[i].active == 1 then
            found = owned[i]
            break
        end
    end
    if not found then
        return { ok = false, error = 'no_active_pet', message = Locale.no_active_pet }
    end
    local item = GetCatalogItem(found.item_id)
    if not item or not item.petModel then
        return { ok = false, error = 'invalid', message = 'That is not a pet.' }
    end
    TriggerClientEvent('dj-donator:client:spawnPet', source, item.petModel, item.label)
    return { ok = true }
end)

RegisterDonatorCallback('despawnPet', function(source)
    TriggerClientEvent('dj-donator:client:despawnPet', source)
    return { ok = true }
end)

local function adminCoins(source, payload, mode)
    if source ~= 0 and not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission', message = Locale.no_permission }
    end
    local amount = tonumber(payload.amount)
    if not amount or amount < 0 or amount ~= math.floor(amount) then
        return { ok = false, error = 'invalid_amount', message = Locale.invalid_amount }
    end
    local targetSource, targetIdentifier, targetName = resolveTarget(payload)
    if not targetIdentifier then
        return { ok = false, error = 'invalid_player', message = Locale.invalid_player }
    end
    local actorId, actorName = 'console', 'Console'
    if source ~= 0 then
        actorId, actorName = Framework.GetIdentifier(source)
    end

    local result
    if mode == 'set' then
        result = DB.SetCoins(targetIdentifier, amount)
    elseif mode == 'remove' then
        result = DB.AddCoins(targetIdentifier, -amount)
    else
        result = DB.AddCoins(targetIdentifier, amount)
    end

    local reason = payload.reason or ''
    DB.InsertLog(actorId, actorName, targetIdentifier, targetName, 'coins_' .. mode, {
        amount = amount,
        reason = reason,
        balance = result.coins,
    })
    Webhooks.Coins(actorName, actorId, targetName, targetIdentifier, mode, amount, reason)
    if targetSource then
        Framework.Notify(targetSource, Locale.coins_received .. (' (%s %s)'):format(mode == 'remove' and ('-' .. amount) or amount, Config.CurrencyShort), 'success')
        TriggerClientEvent('dj-donator:client:coinsUpdated', targetSource, result.coins)
    end
    if source ~= 0 then
        Framework.Notify(source, Locale.coins_granted, 'success')
    end
    local snap = source ~= 0 and playerSnapshot(source) or nil
    return {
        ok = true,
        player = snap,
        targetBalance = result.coins,
        admin = source ~= 0 and Framework.IsAdmin(source) and { players = onlinePlayers(), logs = DB.GetLogs(40), codes = DB.ListCodes() } or nil,
    }
end

RegisterDonatorCallback('adminGive', function(source, payload)
    return adminCoins(source, payload, 'give')
end)

RegisterDonatorCallback('adminRemove', function(source, payload)
    return adminCoins(source, payload, 'remove')
end)

RegisterDonatorCallback('adminSet', function(source, payload)
    return adminCoins(source, payload, 'set')
end)

RegisterDonatorCallback('adminRefresh', function(source)
    if not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission' }
    end
    return {
        ok = true,
        admin = { players = onlinePlayers(), logs = DB.GetLogs(40), codes = DB.ListCodes() },
        player = playerSnapshot(source),
    }
end)

RegisterDonatorCallback('adminCreateCode', function(source, payload)
    if not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission', message = Locale.no_permission }
    end
    local actorId, actorName = Framework.GetIdentifier(source)
    local code = tostring(payload.code or ''):gsub('%s+', ''):upper()
    if code == '' then
        code = ('RC%06d'):format(math.random(0, 999999))
    end
    local coins = tonumber(payload.coins) or 0
    local maxUses = tonumber(payload.maxUses) or 1
    local expiresAt = payload.expiresAt and payload.expiresAt ~= '' and payload.expiresAt or nil
    local itemId = payload.itemId and payload.itemId ~= '' and payload.itemId or nil
    DB.CreateCode(code, coins, itemId, maxUses, expiresAt, actorId)
    DB.InsertLog(actorId, actorName, nil, nil, 'create_code', { code = code, coins = coins })
    Webhooks.Admin(actorName, actorId, 'create_code', ('Created code %s (%s RC, %s uses)'):format(code, coins, maxUses))
    return { ok = true, admin = { players = onlinePlayers(), logs = DB.GetLogs(40), codes = DB.ListCodes() } }
end)

RegisterDonatorCallback('adminLookup', function(source, payload)
    if not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission' }
    end
    local identifier = payload.identifier
    if not identifier or identifier == '' then
        local src = tonumber(payload.targetId)
        if src then
            identifier = Framework.GetIdentifier(src)
        end
    end
    if not identifier then
        return { ok = false, error = 'invalid_player', message = Locale.invalid_player }
    end
    local coins = DB.GetCoins(identifier)
    return {
        ok = true,
        lookup = {
            identifier = identifier,
            coins = coins,
            owned = DB.GetOwned(identifier),
            history = DB.GetPurchases(identifier, 40),
        },
    }
end)

RegisterDonatorCallback('adminRefund', function(source, payload)
    if not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission', message = Locale.no_permission }
    end
    local purchase = DB.GetPurchaseById(tonumber(payload.purchaseId))
    if not purchase then
        return { ok = false, error = 'invalid', message = 'Purchase not found.' }
    end
    DB.AddCoins(purchase.identifier, purchase.price)
    DB.DeactivateOwned(purchase.identifier, purchase.item_id)
    local catalogItem = GetCatalogItem(purchase.item_id)
    local target = Framework.GetPlayerByIdentifier(purchase.identifier)
    if target and catalogItem and OxInv and OxInv.Ready() then
        OxInv.RemoveGrants(target, catalogItem)
    end
    local actorId, actorName = Framework.GetIdentifier(source)
    DB.InsertLog(actorId, actorName, purchase.identifier, purchase.player_name, 'refund', {
        purchaseId = purchase.id,
        item = purchase.item_id,
        amount = purchase.price,
    })
    Webhooks.Admin(actorName, actorId, 'refund', ('Refunded %s RC for %s to %s'):format(purchase.price, purchase.label, purchase.identifier))
    if target then
        Framework.Notify(target, Locale.refunded, 'inform')
        TriggerClientEvent('dj-donator:client:coinsUpdated', target, DB.GetCoins(purchase.identifier).coins)
    end
    return { ok = true, admin = { players = onlinePlayers(), logs = DB.GetLogs(40), codes = DB.ListCodes() } }
end)

local function commandTarget(src, idArg)
    local target = tonumber(idArg)
    if not target or not GetPlayerName(target) then
        if src ~= 0 then
            Framework.Notify(src, Locale.invalid_player, 'error')
        else
            print('[dj-donator] Invalid player id')
        end
        return
    end
    return target
end

local function ensureAdmin(src)
    if src == 0 then
        return true
    end
    if Framework.IsAdmin(src) then
        return true
    end
    Framework.Notify(src, Locale.no_permission, 'error')
    return false
end

RegisterCommand('givecoins', function(src, args)
    if not ensureAdmin(src) then return end
    local target = commandTarget(src, args[1])
    local amount = tonumber(args[2])
    if not target or not amount then
        return
    end
    local reason = table.concat(args, ' ', 3)
    adminCoins(src, { targetId = target, amount = amount, reason = reason }, 'give')
end, false)

RegisterCommand('removecoins', function(src, args)
    if not ensureAdmin(src) then return end
    local target = commandTarget(src, args[1])
    local amount = tonumber(args[2])
    if not target or not amount then
        return
    end
    adminCoins(src, { targetId = target, amount = amount, reason = table.concat(args, ' ', 3) }, 'remove')
end, false)

RegisterCommand('setcoins', function(src, args)
    if not ensureAdmin(src) then return end
    local target = commandTarget(src, args[1])
    local amount = tonumber(args[2])
    if not target or not amount then
        return
    end
    adminCoins(src, { targetId = target, amount = amount, reason = table.concat(args, ' ', 3) }, 'set')
end, false)

RegisterCommand('checkcoins', function(src, args)
    if src ~= 0 and not Framework.IsAdmin(src) then
        local identifier = Framework.GetIdentifier(src)
        local coins = DB.GetCoins(identifier)
        Framework.Notify(src, ('%s: %s'):format(Config.CurrencyName, coins.coins), 'inform')
        return
    end
    local target = commandTarget(src, args[1] or src)
    if not target then return end
    local identifier, name = Framework.GetIdentifier(target)
    local coins = DB.GetCoins(identifier)
    local msg = ('%s (%s) has %s %s'):format(name, identifier, coins.coins, Config.CurrencyShort)
    if src == 0 then
        print('[dj-donator] ' .. msg)
    else
        Framework.Notify(src, msg, 'inform')
    end
end, false)

RegisterCommand('coins', function(src)
    if src == 0 then return end
    local identifier = Framework.GetIdentifier(src)
    local coins = DB.GetCoins(identifier)
    Framework.Notify(src, ('%s: %s'):format(Config.CurrencyName, coins.coins), 'inform')
end, false)

RegisterCommand('givecoinsid', function(src, args)
    if not ensureAdmin(src) then return end
    local identifier = args[1]
    local amount = tonumber(args[2])
    if not identifier or not amount then
        print('Usage: givecoinsid <identifier> <amount> [reason]')
        return
    end
    adminCoins(src, { identifier = identifier, amount = amount, reason = table.concat(args, ' ', 3) }, 'give')
end, false)

AddEventHandler('playerDropped', function()
    cooldowns[source] = nil
end)

local function onLoaded(src)
    CreateThread(function()
        Wait(2500)
        if GetPlayerName(src) then
            flushPending(src)
        end
    end)
end

AddEventHandler('esx:playerLoaded', function(playerId)
    onLoaded(playerId)
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
    local src = player and player.PlayerData and player.PlayerData.source
    if src then
        onLoaded(src)
    end
end)

RegisterNetEvent('dj-donator:server:playerReady', function()
    onLoaded(source)
end)

exports('GetCoins', function(source)
    local identifier = Framework.GetIdentifier(source)
    return DB.GetCoins(identifier).coins
end)

exports('AddCoins', function(source, amount, reason)
    local identifier, name = Framework.GetIdentifier(source)
    local result = DB.AddCoins(identifier, amount)
    DB.InsertLog('export', 'export', identifier, name, 'coins_give', { amount = amount, reason = reason })
    Webhooks.Coins('export', 'export', name, identifier, 'give', amount, reason or 'export')
    return result.coins
end)

exports('AddCoinsIdentifier', function(identifier, amount, reason)
    local result = DB.AddCoins(identifier, amount)
    DB.InsertLog('export', 'export', identifier, nil, 'coins_give', { amount = amount, reason = reason })
    return result.coins
end)

CreateThread(function()
    Wait(1000)
    local ok = pcall(function()
        MySQL.query.await('SELECT 1 FROM dj_donator_coins LIMIT 1')
    end)
    if not ok then
        print('[dj-donator] WARNING: SQL tables are missing. Import sql/install.sql')
        Webhooks.Error('Database missing', 'Import sql/install.sql before using dj-donator.')
    end
end)
