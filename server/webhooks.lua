Webhooks = {}

local function post(url, payload)
    if not url or url == '' then
        return
    end
    PerformHttpRequest(url, function() end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json',
    })
end

local function embed(title, description, color, fields)
    return {
        username = Config.ServerName .. ' Donator',
        embeds = {
            {
                title = title,
                description = description,
                color = color,
                fields = fields,
                footer = { text = Config.ServerName .. ' • dj-donator' },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ'),
            },
        },
    }
end

function Webhooks.Purchase(actorName, actorId, item, price, giftedTo)
    local fields = {
        { name = 'Player', value = ('%s\n`%s`'):format(actorName or 'Unknown', actorId or 'n/a'), inline = true },
        { name = 'Item', value = ('%s (`%s`)'):format(item.label, item.id), inline = true },
        { name = 'Price', value = tostring(price) .. ' RC', inline = true },
        { name = 'Category', value = item.category or 'n/a', inline = true },
        { name = 'Tier', value = item.tier or '—', inline = true },
    }
    if giftedTo then
        fields[#fields + 1] = { name = 'Gifted To', value = giftedTo, inline = true }
    end
    post(Config.Webhooks.purchases, embed('Donator Purchase', giftedTo and 'A donator item was gifted.' or 'A donator item was purchased.', Config.WebhookColor.purchase, fields))
end

function Webhooks.Coins(actorName, actorId, targetName, targetId, action, amount, reason)
    post(Config.Webhooks.coins, embed('Rebel Coins ' .. action, reason or 'No reason provided.', Config.WebhookColor.coins, {
        { name = 'Admin', value = ('%s\n`%s`'):format(actorName or 'Console', actorId or 'console'), inline = true },
        { name = 'Target', value = ('%s\n`%s`'):format(targetName or 'Unknown', targetId or 'n/a'), inline = true },
        { name = 'Amount', value = tostring(amount), inline = true },
        { name = 'Action', value = action, inline = true },
    }))
end

function Webhooks.Admin(actorName, actorId, action, details)
    post(Config.Webhooks.admin, embed('Admin Action', details or '', Config.WebhookColor.admin, {
        { name = 'Admin', value = ('%s\n`%s`'):format(actorName or 'Console', actorId or 'console'), inline = true },
        { name = 'Action', value = action, inline = true },
    }))
end

function Webhooks.Error(title, details)
    post(Config.Webhooks.errors, embed(title or 'Donator Error', details or '', Config.WebhookColor.error, {}))
end
