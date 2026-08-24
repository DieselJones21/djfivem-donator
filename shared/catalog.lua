local function veh(model)
    return Config.VehicleImage(model)
end

--[[
    Catalog item fields:
    id, label, description, price, category, tier?, model?, item?, weapon?,
    unique?, stock?, limitedFrom?, limitedUntil?, image?, ammo?,
    petModel?, extras? (inventory items granted with purchase)
]]

Catalog = {
    vehicles = {
        bronze = {
            {
                id = 'veh_sultan',
                label = 'Karin Sultan',
                description = 'Reliable street sedan with room to grow. A solid first donator car.',
                model = 'sultan',
                price = 250,
                unique = false,
                image = veh('sultan'),
            },
            {
                id = 'veh_buffalo',
                label = 'Bravado Buffalo',
                description = 'Muscle coupe that holds its own in city chases.',
                model = 'buffalo',
                price = 300,
                unique = false,
                image = veh('buffalo'),
            },
            {
                id = 'veh_futo',
                label = 'Karin Futo',
                description = 'Lightweight drift chassis for late-night canyon runs.',
                model = 'futo',
                price = 220,
                unique = false,
                image = veh('futo'),
            },
            {
                id = 'veh_bati',
                label = 'Pegassi Bati 801',
                description = 'Fast, loud, and always first off the line.',
                model = 'bati',
                price = 280,
                unique = false,
                image = veh('bati'),
            },
            {
                id = 'veh_bison',
                label = 'Bravado Bison',
                description = 'Workhorse pickup with space for crew and cargo.',
                model = 'bison',
                price = 200,
                unique = false,
                image = veh('bison'),
            },
            {
                id = 'veh_oracle2',
                label = 'Ubermacht Oracle XS',
                description = 'Clean executive sedan for moving through the city unnoticed.',
                model = 'oracle2',
                price = 260,
                unique = false,
                image = veh('oracle2'),
            },
        },
        silver = {
            {
                id = 'veh_elegy2',
                label = 'Annis Elegy RH8',
                description = 'Iconic tuner with the grip and power silver donors expect.',
                model = 'elegy2',
                price = 650,
                unique = false,
                image = veh('elegy2'),
            },
            {
                id = 'veh_jester',
                label = 'Dinka Jester',
                description = 'Mid-engine sports car built for tight city circuits.',
                model = 'jester',
                price = 700,
                unique = false,
                image = veh('jester'),
            },
            {
                id = 'veh_comet2',
                label = 'Pfister Comet',
                description = 'Balanced sports coupe with a premium cabin.',
                model = 'comet2',
                price = 680,
                unique = false,
                image = veh('comet2'),
            },
            {
                id = 'veh_sultanrs',
                label = 'Karin Sultan RS',
                description = 'Widebody sultan with serious straight-line speed.',
                model = 'sultanrs',
                price = 800,
                unique = false,
                image = veh('sultanrs'),
            },
            {
                id = 'veh_double',
                label = 'Dinka Double-T',
                description = 'High-end sport bike for silver-tier riders.',
                model = 'double',
                price = 620,
                unique = false,
                image = veh('double'),
            },
            {
                id = 'veh_dominator',
                label = 'Vapid Dominator',
                description = 'American muscle with a donator-only livery option.',
                model = 'dominator',
                price = 640,
                unique = false,
                image = veh('dominator'),
            },
        },
        gold = {
            {
                id = 'veh_t20',
                label = 'Progen T20',
                description = 'Flagship hypercar. Gold tier only.',
                model = 't20',
                price = 1800,
                unique = false,
                image = veh('t20'),
            },
            {
                id = 'veh_zentorno',
                label = 'Pegassi Zentorno',
                description = 'Aggressive wedge hypercar with brutal acceleration.',
                model = 'zentorno',
                price = 1750,
                unique = false,
                image = veh('zentorno'),
            },
            {
                id = 'veh_krieger',
                label = 'Benefactor Krieger',
                description = 'Modern hypercar with track-ready aero.',
                model = 'krieger',
                price = 2100,
                unique = false,
                image = veh('krieger'),
            },
            {
                id = 'veh_adder',
                label = 'Truffade Adder',
                description = 'Classic gold-tier exotic for the boulevard.',
                model = 'adder',
                price = 1600,
                unique = false,
                image = veh('adder'),
            },
            {
                id = 'veh_buzzard2',
                label = 'Buzzard Attack Chopper',
                description = 'Personal air support. Stored as an air vehicle.',
                model = 'buzzard2',
                price = 3200,
                unique = true,
                garageType = 'heli',
                image = veh('buzzard2'),
            },
            {
                id = 'veh_vigilante',
                label = 'Grotti Vigilante',
                description = 'Rocket-boosted superhero car. Handle with care.',
                model = 'vigilante',
                price = 2800,
                unique = true,
                image = veh('vigilante'),
            },
        },
    },

    weapons = {
        bronze = {
            {
                id = 'wep_pistol',
                label = 'Pistol',
                description = 'Standard sidearm with a starter ammo pack.',
                weapon = 'WEAPON_PISTOL',
                item = 'WEAPON_PISTOL',
                ammo = 60,
                price = 150,
                unique = false,
            },
            {
                id = 'wep_combatpistol',
                label = 'Combat Pistol',
                description = 'Compact, reliable, and easy to conceal.',
                weapon = 'WEAPON_COMBATPISTOL',
                item = 'WEAPON_COMBATPISTOL',
                ammo = 60,
                price = 180,
                unique = false,
            },
            {
                id = 'wep_microsmg',
                label = 'Micro SMG',
                description = 'Close-quarters spray with a donator ammo crate.',
                weapon = 'WEAPON_MICROSMG',
                item = 'WEAPON_MICROSMG',
                ammo = 90,
                price = 220,
                unique = false,
            },
            {
                id = 'wep_pumpshotgun',
                label = 'Pump Shotgun',
                description = 'Door-kicker classic. Includes slug box.',
                weapon = 'WEAPON_PUMPSHOTGUN',
                item = 'WEAPON_PUMPSHOTGUN',
                ammo = 32,
                price = 240,
                unique = false,
            },
        },
        silver = {
            {
                id = 'wep_smg',
                label = 'SMG',
                description = 'Full-size SMG with extended ammo.',
                weapon = 'WEAPON_SMG',
                item = 'WEAPON_SMG',
                ammo = 120,
                price = 420,
                unique = false,
            },
            {
                id = 'wep_carbinerifle',
                label = 'Carbine Rifle',
                description = 'The silver-tier workhorse rifle.',
                weapon = 'WEAPON_CARBINERIFLE',
                item = 'WEAPON_CARBINERIFLE',
                ammo = 120,
                price = 550,
                unique = false,
            },
            {
                id = 'wep_specialcarbine',
                label = 'Special Carbine',
                description = 'Accurate, controllable, and built for longer fights.',
                weapon = 'WEAPON_SPECIALCARBINE',
                item = 'WEAPON_SPECIALCARBINE',
                ammo = 120,
                price = 600,
                unique = false,
            },
            {
                id = 'wep_assaultshotgun',
                label = 'Assault Shotgun',
                description = 'Automatic shotgun for silver donors who like close work.',
                weapon = 'WEAPON_ASSAULTSHOTGUN',
                item = 'WEAPON_ASSAULTSHOTGUN',
                ammo = 40,
                price = 580,
                unique = false,
            },
        },
        gold = {
            {
                id = 'wep_pistol50',
                label = 'Pistol .50',
                description = 'Heavy pistol with stopping power to match gold tier.',
                weapon = 'WEAPON_PISTOL50',
                item = 'WEAPON_PISTOL50',
                ammo = 48,
                price = 900,
                unique = false,
            },
            {
                id = 'wep_combatmg',
                label = 'Combat MG',
                description = 'Sustained fire platform. Not for subtle jobs.',
                weapon = 'WEAPON_COMBATMG',
                item = 'WEAPON_COMBATMG',
                ammo = 200,
                price = 1400,
                unique = false,
            },
            {
                id = 'wep_marksmanrifle',
                label = 'Marksman Rifle',
                description = 'Precision rifle for gold-tier operators.',
                weapon = 'WEAPON_MARKSMANRIFLE',
                item = 'WEAPON_MARKSMANRIFLE',
                ammo = 40,
                price = 1300,
                unique = false,
            },
            {
                id = 'wep_rpg',
                label = 'RPG',
                description = 'Single-use heavy hitter. Limited stock recommended.',
                weapon = 'WEAPON_RPG',
                item = 'WEAPON_RPG',
                ammo = 4,
                price = 2200,
                unique = false,
                stock = 25,
            },
        },
    },

    extras = {
        {
            id = 'ext_armor_pack',
            label = 'Armor Crate',
            description = 'Five heavy armor plates delivered to inventory.',
            price = 120,
            extras = {
                { item = 'armour', count = 5 },
            },
        },
        {
            id = 'ext_med_pack',
            label = 'Field Medic Kit',
            description = 'Bandages and medikits delivered through ox_inventory.',
            price = 90,
            extras = {
                { item = 'bandage', count = 10 },
                { item = 'medikit', count = 4 },
            },
        },
        {
            id = 'ext_lockpick',
            label = 'Lockpick Set',
            description = 'A stack of lockpicks delivered through ox_inventory.',
            price = 80,
            extras = {
                { item = 'lockpick', count = 8 },
            },
        },
        {
            id = 'ext_repair',
            label = 'Mobile Repair Kit',
            description = 'Repair kits and a jerry can for roadside recoveries.',
            price = 110,
            extras = {
                { item = 'repairkit', count = 5 },
                { item = 'WEAPON_PETROLCAN', count = 1 },
            },
        },
        {
            id = 'ext_radio',
            label = 'Encrypted Radio',
            description = 'Long-range encrypted radio for crew comms.',
            price = 70,
            extras = {
                { item = 'radio', count = 1 },
            },
        },
        {
            id = 'ext_phone_pack',
            label = 'Burner Phone Bundle',
            description = 'Spare phones for identities that need a reset.',
            price = 60,
            extras = {
                { item = 'phone', count = 2 },
            },
        },
        {
            id = 'ext_ammo_crate',
            label = 'Mixed Ammo Crate',
            description = 'Pistol, rifle, and shotgun ammo in one drop.',
            price = 140,
            extras = {
                { item = 'ammo-9', count = 120 },
                { item = 'ammo-rifle', count = 120 },
                { item = 'ammo-shotgun', count = 40 },
            },
        },
        {
            id = 'ext_starter_pack',
            label = 'Rebel Starter Pack',
            description = 'Armor, meds, lockpicks, and a pistol via ox_inventory.',
            price = 350,
            unique = true,
            extras = {
                { item = 'armour', count = 3 },
                { item = 'bandage', count = 10 },
                { item = 'lockpick', count = 4 },
                { item = 'WEAPON_PISTOL', count = 1 },
            },
        },
    },

    exclusives = {
        {
            id = 'ex_nightshark',
            label = 'HVY Nightshark',
            description = 'Armored city exclusive. One per character.',
            categoryOverride = 'vehicle',
            model = 'nightshark',
            price = 2600,
            unique = true,
            image = veh('nightshark'),
        },
        {
            id = 'ex_paragon2',
            label = 'Enus Paragon R (Armored)',
            description = 'Executive armored coupe that never appears in public dealers.',
            categoryOverride = 'vehicle',
            model = 'paragon2',
            price = 2400,
            unique = true,
            image = veh('paragon2'),
        },
        {
            id = 'ex_oppressor',
            label = 'Pegassi Oppressor',
            description = 'City exclusive bike. Unique ownership, never restocked for the same character.',
            categoryOverride = 'vehicle',
            model = 'oppressor',
            price = 3500,
            unique = true,
            image = veh('oppressor'),
        },
        {
            id = 'ex_carbineluxe',
            label = 'Carbine Rifle MK2',
            description = 'Exclusive MK2 platform with ammo. One per character.',
            weapon = 'WEAPON_CARBINERIFLE_MK2',
            item = 'WEAPON_CARBINERIFLE_MK2',
            ammo = 150,
            price = 1600,
            unique = true,
        },
        {
            id = 'ex_gold_plate',
            label = 'Rebel Gold Plate Pass',
            description = 'Unlocks donator-only number plate style (metadata flag).',
            price = 500,
            unique = true,
            extras = {
                { item = 'donator_plate', count = 1 },
            },
        },
        {
            id = 'ex_penthouse',
            label = 'Penthouse Access Card',
            description = 'City exclusive keycard for the Rebel penthouse interior.',
            price = 2000,
            unique = true,
            extras = {
                { item = 'penthouse_card', count = 1 },
            },
        },
    },

    limited = {
        {
            id = 'lim_summer_growler',
            label = 'Summer Growler',
            description = 'Seasonal sports wagon. Leaves the store when the window closes.',
            categoryOverride = 'vehicle',
            model = 'growler',
            price = 900,
            unique = false,
            limitedFrom = '2026-08-01T00:00:00Z',
            limitedUntil = '2026-09-15T23:59:59Z',
            stock = 40,
            image = veh('growler'),
        },
        {
            id = 'lim_weekend_smg',
            label = 'Weekend Combat PDW',
            description = 'Flash deal SMG. Timer is enforced server-side.',
            weapon = 'WEAPON_COMBATPDW',
            item = 'WEAPON_COMBATPDW',
            ammo = 140,
            price = 380,
            limitedFrom = '2026-08-20T00:00:00Z',
            limitedUntil = '2026-08-31T23:59:59Z',
            stock = 80,
        },
        {
            id = 'lim_panther',
            label = 'Limited Panther',
            description = 'Rare companion panther. Only available during this window.',
            petModel = 'a_c_panther',
            price = 1500,
            unique = true,
            limitedFrom = '2026-08-01T00:00:00Z',
            limitedUntil = '2026-09-30T23:59:59Z',
            stock = 15,
        },
        {
            id = 'lim_toros',
            label = 'Pegassi Toros Drop',
            description = 'Limited luxury SUV drop for late summer.',
            categoryOverride = 'vehicle',
            model = 'toros',
            price = 1100,
            unique = false,
            limitedFrom = '2026-08-10T00:00:00Z',
            limitedUntil = '2026-09-10T23:59:59Z',
            stock = 30,
            image = veh('toros'),
        },
    },

    pets = {
        {
            id = 'pet_husky',
            label = 'Husky',
            description = 'Loyal husky that follows you around the city.',
            petModel = 'a_c_husky',
            price = 400,
            unique = true,
        },
        {
            id = 'pet_retriever',
            label = 'Retriever',
            description = 'Friendly retriever. One active pet at a time.',
            petModel = 'a_c_retriever',
            price = 380,
            unique = true,
        },
        {
            id = 'pet_rottweiler',
            label = 'Rottweiler',
            description = 'Protective rottweiler companion.',
            petModel = 'a_c_rottweiler',
            price = 450,
            unique = true,
        },
        {
            id = 'pet_pug',
            label = 'Pug',
            description = 'Small, stubborn, and surprisingly fast.',
            petModel = 'a_c_pug',
            price = 320,
            unique = true,
        },
        {
            id = 'pet_cat',
            label = 'Cat',
            description = 'Street cat that decided you are its person.',
            petModel = 'a_c_cat_01',
            price = 300,
            unique = true,
        },
        {
            id = 'pet_poodle',
            label = 'Poodle',
            description = 'Show-dog energy with donator-only collar metadata.',
            petModel = 'a_c_poodle',
            price = 360,
            unique = true,
        },
    },
}

function GetCatalogItem(itemId)
    local function scan(list, category, tier)
        for i = 1, #list do
            local item = list[i]
            if item.id == itemId then
                local copy = {}
                for k, v in pairs(item) do
                    copy[k] = v
                end
                copy.category = category
                copy.tier = tier
                return copy
            end
        end
    end

    for tier, list in pairs(Catalog.vehicles) do
        local found = scan(list, 'vehicles', tier)
        if found then return found end
    end
    for tier, list in pairs(Catalog.weapons) do
        local found = scan(list, 'weapons', tier)
        if found then return found end
    end

    local maps = {
        extras = 'extras',
        exclusives = 'exclusives',
        limited = 'limited',
        pets = 'pets',
    }
    for key, category in pairs(maps) do
        local found = scan(Catalog[key], category, nil)
        if found then return found end
    end
end
