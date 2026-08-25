DB = {}

function DB.EnsurePlayer(identifier)
    MySQL.query.await(
        'INSERT INTO dj_donator_coins (identifier, coins) VALUES (?, 0) ON DUPLICATE KEY UPDATE identifier = identifier',
        { identifier }
    )
end

function DB.GetCoins(identifier)
    DB.EnsurePlayer(identifier)
    local row = MySQL.single.await('SELECT coins, lifetime_spent, lifetime_granted FROM dj_donator_coins WHERE identifier = ?', { identifier })
    return row or { coins = 0, lifetime_spent = 0, lifetime_granted = 0 }
end

function DB.AddCoins(identifier, amount)
    DB.EnsurePlayer(identifier)
    if amount >= 0 then
        MySQL.update.await(
            'UPDATE dj_donator_coins SET coins = coins + ?, lifetime_granted = lifetime_granted + ? WHERE identifier = ?',
            { amount, amount, identifier }
        )
    else
        MySQL.update.await(
            'UPDATE dj_donator_coins SET coins = GREATEST(0, coins + ?) WHERE identifier = ?',
            { amount, identifier }
        )
    end
    return DB.GetCoins(identifier)
end

function DB.SetCoins(identifier, amount)
    DB.EnsurePlayer(identifier)
    MySQL.update.await('UPDATE dj_donator_coins SET coins = ? WHERE identifier = ?', { amount, identifier })
    return DB.GetCoins(identifier)
end

function DB.TrySpend(identifier, amount)
    DB.EnsurePlayer(identifier)
    local changed = MySQL.update.await(
        'UPDATE dj_donator_coins SET coins = coins - ?, lifetime_spent = lifetime_spent + ? WHERE identifier = ? AND coins >= ?',
        { amount, amount, identifier, amount }
    )
    return changed and changed > 0
end

function DB.OwnsUnique(identifier, itemId)
    local row = MySQL.single.await(
        'SELECT id FROM dj_donator_owned WHERE identifier = ? AND item_id = ? AND active = 1 LIMIT 1',
        { identifier, itemId }
    )
    return row ~= nil
end

function DB.InsertOwned(identifier, item, data)
    return MySQL.insert.await(
        'INSERT INTO dj_donator_owned (identifier, item_id, category, tier, label, data, active) VALUES (?, ?, ?, ?, ?, ?, 1)',
        { identifier, item.id, item.category, item.tier, item.label, json.encode(data or {}) }
    )
end

function DB.GetOwned(identifier)
    return MySQL.query.await(
        'SELECT id, item_id, category, tier, label, data, active, created_at FROM dj_donator_owned WHERE identifier = ? ORDER BY created_at DESC',
        { identifier }
    ) or {}
end

function DB.InsertPurchase(identifier, playerName, item, price, quantity, giftedTo)
    return MySQL.insert.await(
        'INSERT INTO dj_donator_purchases (identifier, player_name, item_id, label, category, tier, price, quantity, gifted_to) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        { identifier, playerName, item.id, item.label, item.category, item.tier, price, quantity or 1, giftedTo }
    )
end

function DB.GetPurchases(identifier, limit)
    return MySQL.query.await(
        'SELECT id, item_id, label, category, tier, price, quantity, gifted_to, created_at FROM dj_donator_purchases WHERE identifier = ? ORDER BY created_at DESC LIMIT ?',
        { identifier, limit or 25 }
    ) or {}
end

function DB.GetSpendSeries(identifier)
    return MySQL.query.await(
        [[SELECT DATE(created_at) AS day, SUM(price) AS total
          FROM dj_donator_purchases
          WHERE identifier = ? AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)
          GROUP BY DATE(created_at)
          ORDER BY day ASC]],
        { identifier }
    ) or {}
end

function DB.InsertLog(actorId, actorName, targetId, targetName, action, details)
    MySQL.insert(
        'INSERT INTO dj_donator_logs (actor_identifier, actor_name, target_identifier, target_name, action, details) VALUES (?, ?, ?, ?, ?, ?)',
        { actorId, actorName, targetId, targetName, action, type(details) == 'string' and details or json.encode(details or {}) }
    )
end

function DB.GetLogs(limit)
    return MySQL.query.await(
        'SELECT id, actor_identifier, actor_name, target_identifier, target_name, action, details, created_at FROM dj_donator_logs ORDER BY id DESC LIMIT ?',
        { limit or 50 }
    ) or {}
end

function DB.DecrementStockNote(itemId)
    -- Stock is enforced from in-memory counters seeded from config + purchase counts.
end

function DB.CountItemSold(itemId)
    local row = MySQL.single.await('SELECT COUNT(*) AS n FROM dj_donator_purchases WHERE item_id = ?', { itemId })
    return row and tonumber(row.n) or 0
end

function DB.GetCode(code)
    return MySQL.single.await('SELECT * FROM dj_donator_codes WHERE code = ?', { code })
end

function DB.CreateCode(code, coins, itemId, maxUses, expiresAt, createdBy)
    return MySQL.insert.await(
        'INSERT INTO dj_donator_codes (code, coins, item_id, max_uses, uses, expires_at, created_by) VALUES (?, ?, ?, ?, 0, ?, ?)',
        { code, coins or 0, itemId, maxUses or 1, expiresAt, createdBy }
    )
end

function DB.HasRedeemed(codeId, identifier)
    local row = MySQL.single.await(
        'SELECT id FROM dj_donator_code_redemptions WHERE code_id = ? AND identifier = ?',
        { codeId, identifier }
    )
    return row ~= nil
end

function DB.RedeemCode(codeId, identifier)
    MySQL.update.await('UPDATE dj_donator_codes SET uses = uses + 1 WHERE id = ?', { codeId })
    MySQL.insert.await(
        'INSERT INTO dj_donator_code_redemptions (code_id, identifier) VALUES (?, ?)',
        { codeId, identifier }
    )
end

function DB.ListCodes()
    return MySQL.query.await('SELECT id, code, coins, item_id, max_uses, uses, expires_at, created_at FROM dj_donator_codes ORDER BY id DESC LIMIT 50') or {}
end

function DB.GetPurchaseById(id)
    return MySQL.single.await('SELECT * FROM dj_donator_purchases WHERE id = ?', { id })
end

function DB.DeactivateOwned(identifier, itemId)
    MySQL.update.await(
        'UPDATE dj_donator_owned SET active = 0 WHERE identifier = ? AND item_id = ?',
        { identifier, itemId }
    )
end

function DB.EnsureListingsTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `dj_donator_listings` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `item_id` VARCHAR(64) NOT NULL,
            `category` VARCHAR(32) NOT NULL,
            `tier` VARCHAR(16) DEFAULT NULL,
            `label` VARCHAR(128) NOT NULL,
            `description` TEXT,
            `price` INT NOT NULL DEFAULT 0,
            `image` VARCHAR(512) DEFAULT NULL,
            `image_key` VARCHAR(64) DEFAULT NULL,
            `item_name` VARCHAR(64) DEFAULT NULL,
            `weapon` VARCHAR(64) DEFAULT NULL,
            `model` VARCHAR(64) DEFAULT NULL,
            `pet_model` VARCHAR(64) DEFAULT NULL,
            `ammo` INT DEFAULT NULL,
            `item_count` INT NOT NULL DEFAULT 1,
            `extras` LONGTEXT,
            `unique_item` TINYINT(1) NOT NULL DEFAULT 0,
            `stock` INT DEFAULT NULL,
            `limited_from` VARCHAR(32) DEFAULT NULL,
            `limited_until` VARCHAR(32) DEFAULT NULL,
            `garage_id` VARCHAR(64) DEFAULT NULL,
            `garage_type` VARCHAR(16) DEFAULT NULL,
            `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `item_id` (`item_id`),
            KEY `category` (`category`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ]])
end

function DB.GetListings()
    return MySQL.query.await('SELECT * FROM dj_donator_listings ORDER BY category ASC, tier ASC, id ASC') or {}
end

function DB.UpsertListing(item, count)
    local extras = item.extras and json.encode(item.extras) or nil
    MySQL.query.await([[
        INSERT INTO dj_donator_listings
            (item_id, category, tier, label, description, price, image, image_key, item_name, weapon, model, pet_model, ammo, item_count, extras, unique_item, stock, limited_from, limited_until, garage_id, garage_type)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE
            category = VALUES(category),
            tier = VALUES(tier),
            label = VALUES(label),
            description = VALUES(description),
            price = VALUES(price),
            image = VALUES(image),
            image_key = VALUES(image_key),
            item_name = VALUES(item_name),
            weapon = VALUES(weapon),
            model = VALUES(model),
            pet_model = VALUES(pet_model),
            ammo = VALUES(ammo),
            item_count = VALUES(item_count),
            extras = VALUES(extras),
            unique_item = VALUES(unique_item),
            stock = VALUES(stock),
            limited_from = VALUES(limited_from),
            limited_until = VALUES(limited_until),
            garage_id = VALUES(garage_id),
            garage_type = VALUES(garage_type)
    ]], {
        item.id,
        item.category,
        item.tier,
        item.label,
        item.description,
        item.price,
        item.image,
        item.imageKey,
        item.item,
        item.weapon,
        item.model,
        item.petModel,
        item.ammo,
        count or (item.extras and item.extras[1] and item.extras[1].count) or 1,
        extras,
        item.unique and 1 or 0,
        item.stock,
        item.limitedFrom,
        item.limitedUntil,
        item.garageId,
        item.garageType,
    })
end

function DB.DeleteListing(itemId)
    MySQL.update.await('DELETE FROM dj_donator_listings WHERE item_id = ?', { itemId })
end
