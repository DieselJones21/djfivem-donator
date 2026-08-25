--[[
    Merge these entries into ox_inventory/data/items.lua.

    Shop and inventory icons come from Fivemanage (Config.Images) via metadata.imageurl
    when a player receives the item from dj-donator. You do not need local PNGs if
    Config.Images.baseUrl is set.

    Optional: set client.image to the same Fivemanage URL so the item also shows
    correctly when given by other scripts.

    Restart ox_inventory after merging.
]]

return {
    ['donator_plate'] = {
        label = 'Rebel Gold Plate Pass',
        weight = 10,
        stack = false,
        close = true,
        consume = 0,
        description = 'Donator plate pass from the Rebel store.',
        client = {
            image = 'nui://dj-donator/html/images/donator_plate.png',
        },
    },
    ['penthouse_card'] = {
        label = 'Penthouse Access Card',
        weight = 5,
        stack = false,
        close = true,
        consume = 0,
        description = 'Keycard for the Rebel penthouse interior.',
        client = {
            image = 'nui://dj-donator/html/images/penthouse_card.png',
        },
    },
    ['repairkit'] = {
        label = 'Repair Kit',
        weight = 2500,
        stack = true,
        close = true,
        description = 'Roadside vehicle repair kit.',
    },
    ['pet_husky'] = {
        label = 'Husky',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        description = 'Use to spawn or dismiss your husky.',
        client = {
            export = 'dj-donator.usePet',
            image = 'nui://dj-donator/html/images/pet_husky.png',
        },
    },
    ['pet_retriever'] = {
        label = 'Retriever',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        description = 'Use to spawn or dismiss your retriever.',
        client = {
            export = 'dj-donator.usePet',
            image = 'nui://dj-donator/html/images/pet_retriever.png',
        },
    },
    ['pet_rottweiler'] = {
        label = 'Rottweiler',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        description = 'Use to spawn or dismiss your rottweiler.',
        client = {
            export = 'dj-donator.usePet',
            image = 'nui://dj-donator/html/images/pet_rottweiler.png',
        },
    },
    ['pet_pug'] = {
        label = 'Pug',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        description = 'Use to spawn or dismiss your pug.',
        client = {
            export = 'dj-donator.usePet',
            image = 'nui://dj-donator/html/images/pet_pug.png',
        },
    },
    ['pet_cat'] = {
        label = 'Cat',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        description = 'Use to spawn or dismiss your cat.',
        client = {
            export = 'dj-donator.usePet',
            image = 'nui://dj-donator/html/images/pet_cat.png',
        },
    },
    ['pet_poodle'] = {
        label = 'Poodle',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        description = 'Use to spawn or dismiss your poodle.',
        client = {
            export = 'dj-donator.usePet',
            image = 'nui://dj-donator/html/images/pet_poodle.png',
        },
    },
    ['lim_panther'] = {
        label = 'Limited Panther',
        weight = 0,
        stack = false,
        close = true,
        consume = 0,
        description = 'Use to spawn or dismiss your panther.',
        client = {
            export = 'dj-donator.usePet',
            image = 'nui://dj-donator/html/images/lim_panther.png',
        },
    },
}
