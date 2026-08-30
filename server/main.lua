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
        vehicles = EmptyTierBuckets(),
        weapons = EmptyTierBuckets(),
        extras = {},
        bundles = {},
        pets = {},
        exclusives = {},
        limited = {},
    }

    for tier, list in pairs(Catalog.vehicles) do
        for i = 1, #list do
            local item = list[i]
            item.category = 'vehicles'
            item.tier = NormalizeTier(tier)
            out.vehicles[item.tier] = out.vehicles[item.tier] or {}
            out.vehicles[item.tier][#out.vehicles[item.tier] + 1] = publicItem(item)
        end
    end
    for tier, list in pairs(Catalog.weapons) do
        for i = 1, #list do
            local item = list[i]
            item.category = 'weapons'
            item.tier = NormalizeTier(tier)
            out.weapons[item.tier] = out.weapons[item.tier] or {}
            out.weapons[item.tier][#out.weapons[item.tier] + 1] = publicItem(item)
        end
    end

    local function fill(src, dest, category)
        for i = 1, #src do
            src[i].category = category
            dest[#dest + 1] = publicItem(src[i])
        end
    end

    fill(Catalog.extras, out.extras, 'extras')
    fill(Catalog.bundles, out.bundles, 'bundles')
    fill(Catalog.pets, out.pets, 'pets')
    fill(Catalog.exclusives, out.exclusives, 'exclusives')
    fill(Catalog.limited, out.limited, 'limited')
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

local function maxGrant()
    return (Config.Tebex and tonumber(Config.Tebex.MaxGrant)) or 250000
end

local function sanitizeAmount(amount, allowZero)
    amount = tonumber(amount)
    if not amount or amount ~= math.floor(amount) then
        return nil
    end
    if amount < (allowZero and 0 or 1) then
        return nil
    end
    if amount > maxGrant() then
        return nil
    end
    return amount
end

local function sanitizeIdentifier(identifier)
    if type(identifier) ~= 'string' then
        return nil
    end
    identifier = identifier:match('^%s*(.-)%s*$')
    if not identifier or identifier == '' or #identifier > 80 then
        return nil
    end
    if identifier:find('[^%w%:%-%_%.]') then
        return nil
    end
    return identifier
end

local function withItemLock(itemId, fn)
    local lockName = ('dj_305donator_%s'):format(tostring(itemId))
    local got = MySQL.scalar.await('SELECT GET_LOCK(?, 4)', { lockName })
    if got ~= 1 then
        return { ok = false, error = 'cooldown', message = Locale.cooldown }
    end
    local ok, result = pcall(fn)
    MySQL.scalar.await('SELECT RELEASE_LOCK(?)', { lockName })
    if not ok then
        print(('[djfivem-305donator] locked action failed: %s'):format(result))
        return { ok = false, error = 'internal', message = 'Could not complete that action.' }
    end
    return result
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
                    MySQL.update.await('UPDATE dj_305donator_owned SET data = ? WHERE id = ?', { json.encode(data), row.id })
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

local function adminBundle()
    return {
        players = onlinePlayers(),
        logs = DB.GetLogs(40),
        codes = DB.ListCodes(),
        listings = Listings.EditorRows(),
    }
end

local function listingError(err)
    return Locale[err] or Locale.listing_invalid or 'Could not save that listing.'
end

RegisterDonatorCallback('open', function(source)
    local snap = playerSnapshot(source)
    if not snap then
        return { ok = false, error = 'invalid_player' }
    end
    local everyone = onlinePlayers()
    local admin = {}
    if snap.isAdmin then
        admin = adminBundle()
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
        theme = Config.Theme or 'miami',
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

    return withItemLock(item.id, function()
        local stillOk, stillReason = canBuy(identifier, item)
        if not stillOk then
            return { ok = false, error = stillReason, message = Locale[stillReason] or 'Cannot buy this item.' }
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
        if item.stock and remainingStock(item) and remainingStock(item) < 0 then
            DB.AddCoins(identifier, item.price)
            DB.DeactivateOwned(identifier, item.id)
            DB.DeleteLastPurchase(identifier, item.id)
            return { ok = false, error = 'out_of_stock', message = Locale.out_of_stock }
        end
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
            TriggerClientEvent('djfivem-305donator:client:ownedPetsUpdated', source)
        else
            Framework.Notify(source, Locale.item_granted, 'success')
        end

        return { ok = true, player = playerSnapshot(source), granted = data }
    end)
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
    if targetSource and Config.MaxGiftDistance and Config.MaxGiftDistance > 0 and not Config.AllowRemoteGifts then
        local buyerPed = GetPlayerPed(source)
        local targetPed = GetPlayerPed(targetSource)
        if buyerPed ~= 0 and targetPed ~= 0 then
            local b = GetEntityCoords(buyerPed)
            local t = GetEntityCoords(targetPed)
            if #(b - t) > Config.MaxGiftDistance then
                return { ok = false, error = 'distance', message = 'That player is too far away.' }
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

    return withItemLock(item.id, function()
        local stillOk, stillReason = canBuy(targetIdentifier, item)
        if not stillOk then
            return { ok = false, error = stillReason, message = Locale[stillReason] or 'Cannot gift this item.' }
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
            TriggerClientEvent('djfivem-305donator:client:ownedPetsUpdated', targetSource)
        end
        return { ok = true, player = playerSnapshot(source), granted = data }
    end)
end)

RegisterDonatorCallback('redeem', function(source, payload)
    if isOnCooldown(source) then
        return { ok = false, error = 'cooldown', message = Locale.cooldown }
    end
    local identifier, name = Framework.GetIdentifier(source)
    local code = payload.code and tostring(payload.code):gsub('%s+', ''):upper() or ''
    if not identifier or code == '' or #code > 32 then
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
        local expires = parseIso(tostring(row.expires_at):gsub(' ', 'T') .. 'Z')
        if expires and nowUtc() > expires then
            return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
        end
    end
    if DB.HasRedeemed(row.id, identifier) then
        return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
    end
    local item
    if row.item_id and row.item_id ~= '' then
        item = GetCatalogItem(row.item_id)
        if item then
            local canOk, canReason = canBuy(identifier, item)
            if not canOk then
                return { ok = false, error = canReason, message = Locale[canReason] or 'Cannot redeem this item.' }
            end
            local invOk, invErr, invMsg = inventoryGate(source, item)
            if not invOk then
                return { ok = false, error = invErr, message = invMsg }
            end
        end
    end

    if not DB.TryRedeemCode(row.id, identifier) then
        return { ok = false, error = 'invalid_code', message = Locale.invalid_code }
    end
    if item then
        local granted = grantItem(source, identifier, item)
        if granted.grantFailed then
            DB.UndoRedeem(row.id, identifier)
            return { ok = false, error = 'inventory_full', message = Locale.inventory_full }
        end
    end
    if row.coins and row.coins > 0 then
        DB.AddCoins(identifier, row.coins)
    end
    DB.InsertLog(identifier, name, identifier, name, 'redeem', { code = code, coins = row.coins, item = row.item_id })
    Webhooks.Admin(name, identifier, 'redeem', ('Redeemed code %s for %s %s'):format(code, tostring(row.coins or 0), Config.CurrencyShort))
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
    TriggerClientEvent('djfivem-305donator:client:spawnPet', source, item.petModel, item.label)
    return { ok = true }
end)

RegisterDonatorCallback('despawnPet', function(source)
    TriggerClientEvent('djfivem-305donator:client:despawnPet', source)
    return { ok = true }
end)

local function adminCoins(source, payload, mode)
    if source ~= 0 and not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission', message = Locale.no_permission }
    end
    local amount = sanitizeAmount(payload.amount, mode == 'set')
    if not amount then
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
        TriggerClientEvent('djfivem-305donator:client:coinsUpdated', targetSource, result.coins)
    end
    if source ~= 0 then
        Framework.Notify(source, Locale.coins_granted, 'success')
    end
    local snap = source ~= 0 and playerSnapshot(source) or nil
    return {
        ok = true,
        player = snap,
        targetBalance = result.coins,
        admin = source ~= 0 and Framework.IsAdmin(source) and adminBundle() or nil,
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
        admin = adminBundle(),
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
        code = ('305%05d'):format(math.random(0, 99999))
    end
    local coins = sanitizeAmount(payload.coins, true) or 0
    local maxUses = math.floor(tonumber(payload.maxUses) or 1)
    if maxUses < 1 or maxUses > 1000 then
        maxUses = 1
    end
    local expiresAt = payload.expiresAt and payload.expiresAt ~= '' and payload.expiresAt or nil
    local itemId = payload.itemId and payload.itemId ~= '' and payload.itemId or nil
    if itemId and not GetCatalogItem(itemId) then
        return { ok = false, error = 'invalid', message = 'That catalog item does not exist.' }
    end
    DB.CreateCode(code, coins, itemId, maxUses, expiresAt, actorId)
    DB.InsertLog(actorId, actorName, nil, nil, 'create_code', { code = code, coins = coins })
    Webhooks.Admin(actorName, actorId, 'create_code', ('Created code %s (%s %s, %s uses)'):format(code, coins, Config.CurrencyShort, maxUses))
    return { ok = true, admin = adminBundle() }
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
    if tonumber(purchase.refunded) == 1 then
        return { ok = false, error = 'invalid', message = 'That purchase was already refunded.' }
    end
    if not DB.TryMarkRefunded(purchase.id) then
        return { ok = false, error = 'invalid', message = 'That purchase was already refunded.' }
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
    Webhooks.Admin(actorName, actorId, 'refund', ('Refunded %s %s for %s to %s'):format(purchase.price, Config.CurrencyShort, purchase.label, purchase.identifier))
    if target then
        Framework.Notify(target, Locale.refunded, 'inform')
        TriggerClientEvent('djfivem-305donator:client:coinsUpdated', target, DB.GetCoins(purchase.identifier).coins)
    end
    return { ok = true, admin = adminBundle() }
end)

RegisterDonatorCallback('adminSaveListing', function(source, payload)
    if not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission', message = Locale.no_permission }
    end
    payload = payload or {}
    local existingId = payload.editingId and payload.editingId ~= '' and payload.editingId or nil
    local item, err = Listings.Save(payload, existingId)
    if not item then
        return { ok = false, error = err, message = listingError(err) }
    end
    local actorId, actorName = Framework.GetIdentifier(source)
    DB.InsertLog(actorId, actorName, nil, nil, existingId and 'edit_listing' or 'add_listing', {
        id = item.id,
        label = item.label,
        category = item.category,
        price = item.price,
    })
    Webhooks.Admin(actorName, actorId, existingId and 'edit_listing' or 'add_listing', ('%s (%s) for %s %s'):format(item.label, item.id, item.price, Config.CurrencyShort))
    return {
        ok = true,
        catalog = publicCatalog(),
        admin = adminBundle(),
        player = playerSnapshot(source),
    }
end)

RegisterDonatorCallback('adminDeleteListing', function(source, payload)
    if not Framework.IsAdmin(source) then
        return { ok = false, error = 'no_permission', message = Locale.no_permission }
    end
    local itemId = payload and payload.itemId
    local existing = GetCatalogItem(itemId)
    if not existing then
        return { ok = false, error = 'invalid', message = 'Listing not found.' }
    end
    Listings.Delete(itemId)
    local actorId, actorName = Framework.GetIdentifier(source)
    DB.InsertLog(actorId, actorName, nil, nil, 'delete_listing', { id = itemId, label = existing.label })
    Webhooks.Admin(actorName, actorId, 'delete_listing', ('Removed %s (`%s`)'):format(existing.label, itemId))
    return {
        ok = true,
        catalog = publicCatalog(),
        admin = adminBundle(),
        player = playerSnapshot(source),
    }
end)

local function commandTarget(src, idArg)
    local target = tonumber(idArg)
    if not target or not GetPlayerName(target) then
        if src ~= 0 then
            Framework.Notify(src, Locale.invalid_player, 'error')
        else
            print('[djfivem-305donator] Invalid player id')
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
    local amount = sanitizeAmount(args[2])
    if not target or not amount then
        return
    end
    local reason = table.concat(args, ' ', 3)
    adminCoins(src, { targetId = target, amount = amount, reason = reason }, 'give')
end, false)

RegisterCommand('removecoins', function(src, args)
    if not ensureAdmin(src) then return end
    local target = commandTarget(src, args[1])
    local amount = sanitizeAmount(args[2])
    if not target or not amount then
        return
    end
    adminCoins(src, { targetId = target, amount = amount, reason = table.concat(args, ' ', 3) }, 'remove')
end, false)

RegisterCommand('setcoins', function(src, args)
    if not ensureAdmin(src) then return end
    local target = commandTarget(src, args[1])
    local amount = sanitizeAmount(args[2], true)
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
        print('[djfivem-305donator] ' .. msg)
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
    local identifier = sanitizeIdentifier(args[1])
    local amount = sanitizeAmount(args[2])
    if not identifier or not amount then
        print('Usage: givecoinsid <identifier> <amount> [reason]')
        return
    end
    adminCoins(src, { identifier = identifier, amount = amount, reason = table.concat(args, ' ', 3) }, 'give')
end, true)

local function resolveGrantTarget(arg)
    local src = tonumber(arg)
    if src and GetPlayerName(src) then
        local identifier, name = Framework.GetIdentifier(src)
        return src, identifier, name
    end
    local identifier = sanitizeIdentifier(arg)
    if not identifier then
        return nil
    end
    return Framework.GetPlayerByIdentifier(identifier), identifier, nil
end

local function tebexGrantCoins(src, args)
    if not ensureAdmin(src) then return end
    local targetSource, identifier = resolveGrantTarget(args[1])
    local amount = sanitizeAmount(args[2])
    if not identifier or not amount then
        print('[djfivem-305donator] Usage: vicegrant <serverId|identifier> <amount> [reason]')
        return
    end
    adminCoins(src, {
        identifier = identifier,
        targetId = targetSource,
        amount = amount,
        reason = table.concat(args, ' ', 3),
    }, 'give')
    if src == 0 then
        print(('[djfivem-305donator] Granted %s %s to %s'):format(amount, Config.CurrencyShort, identifier))
    end
end

local function tebexGrantPackage(src, args)
    if not ensureAdmin(src) then return end
    local targetSource, identifier, name = resolveGrantTarget(args[1])
    local itemId = args[2] and tostring(args[2]) or ''
    if not identifier or itemId == '' then
        print('[djfivem-305donator] Usage: vicepackage <serverId|identifier> <itemId>')
        return
    end
    local item = GetCatalogItem(itemId)
    if not item then
        print('[djfivem-305donator] Unknown catalog item: ' .. itemId)
        return
    end
    local result = withItemLock(item.id, function()
        local canOk, reason = canBuy(identifier, item)
        if not canOk then
            return { ok = false, error = reason }
        end
        local data = grantItem(targetSource, identifier, item)
        if data.grantFailed then
            return { ok = false, error = 'inventory_full' }
        end
        DB.InsertPurchase(identifier, name or 'Tebex', item, 0, 1, 'tebex')
        DB.InsertLog('tebex', 'Tebex', identifier, name, 'tebex_package', { item = item.id })
        Webhooks.Admin('Tebex', 'tebex', 'package', ('Granted %s to %s'):format(item.label, identifier))
        if targetSource then
            Framework.Notify(targetSource, Locale.item_granted, 'success')
        end
        return { ok = true }
    end)
    if src == 0 then
        if result.ok then
            print(('[djfivem-305donator] Granted %s to %s'):format(item.label, identifier))
        else
            print(('[djfivem-305donator] Package grant failed: %s'):format(result.error or 'unknown'))
        end
    end
    return result and result.ok
end

RegisterCommand((Config.Tebex and Config.Tebex.GrantCommand) or 'vicegrant', tebexGrantCoins, true)
RegisterCommand((Config.Tebex and Config.Tebex.PackageCommand) or 'vicepackage', tebexGrantPackage, true)

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

RegisterNetEvent('djfivem-305donator:server:playerReady', function()
    onLoaded(source)
end)

exports('GetCoins', function(source)
    local identifier = Framework.GetIdentifier(source)
    return DB.GetCoins(identifier).coins
end)

exports('AddCoins', function(source, amount, reason)
    amount = sanitizeAmount(amount)
    if not amount then
        return nil
    end
    local identifier, name = Framework.GetIdentifier(source)
    if not identifier then
        return nil
    end
    local result = DB.AddCoins(identifier, amount)
    DB.InsertLog('export', 'export', identifier, name, 'coins_give', { amount = amount, reason = reason })
    Webhooks.Coins('export', 'export', name, identifier, 'give', amount, reason or 'export')
    return result.coins
end)

exports('AddCoinsIdentifier', function(identifier, amount, reason)
    identifier = sanitizeIdentifier(identifier)
    amount = sanitizeAmount(amount)
    if not identifier or not amount then
        return nil
    end
    local result = DB.AddCoins(identifier, amount)
    DB.InsertLog('export', 'export', identifier, nil, 'coins_give', { amount = amount, reason = reason })
    Webhooks.Coins('export', 'export', nil, identifier, 'give', amount, reason or 'export')
    return result.coins
end)

exports('GrantItemIdentifier', function(identifier, itemId)
    identifier = sanitizeIdentifier(identifier)
    if not identifier or type(itemId) ~= 'string' or itemId == '' then
        return false
    end
    return tebexGrantPackage(0, { identifier, itemId }) == true
end)

CreateThread(function()
    Wait(1000)
    local ok = pcall(function()
        MySQL.query.await('SELECT 1 FROM dj_305donator_coins LIMIT 1')
    end)
    if not ok then
        print('[djfivem-305donator] WARNING: SQL tables are missing. Import sql/install.sql')
        Webhooks.Error('Database missing', 'Import sql/install.sql before using djfivem-305donator.')
    else
        DB.EnsureSchema()
        Listings.Rebuild()
        print(('[djfivem-305donator] Shop listings loaded: %s'):format(#CatalogAll()))
    end
end)
