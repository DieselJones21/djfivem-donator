--[[
    Vehicle / weapon shop tiers.
    Old bronze / silver / gold rows are remapped on load.
]]

Tiers = {
    ids = { 'emerald', 'sapphire', 'blackdiamond' },
    labels = {
        emerald = 'Emerald',
        sapphire = 'Sapphire',
        blackdiamond = 'Black Diamond',
    },
    aliases = {
        bronze = 'emerald',
        silver = 'sapphire',
        gold = 'blackdiamond',
        black_diamond = 'blackdiamond',
        ['black diamond'] = 'blackdiamond',
        diamond = 'blackdiamond',
    },
}

function NormalizeTier(tier)
    if type(tier) ~= 'string' or tier == '' then
        return 'emerald'
    end
    local lower = tier:lower()
    local compact = lower:gsub('[%s_%-]+', '')
    if Tiers.aliases[lower] then
        return Tiers.aliases[lower]
    end
    if Tiers.aliases[compact] then
        return Tiers.aliases[compact]
    end
    for i = 1, #Tiers.ids do
        if Tiers.ids[i] == lower or Tiers.ids[i] == compact then
            return Tiers.ids[i]
        end
    end
    return 'emerald'
end

function TierLabel(tier)
    local id = NormalizeTier(tier)
    return Tiers.labels[id] or id
end

function EmptyTierBuckets()
    return { emerald = {}, sapphire = {}, blackdiamond = {} }
end
