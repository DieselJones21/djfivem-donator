fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dj-donator'
author 'DieselJones21'
description 'The 305 donator store with in-game listing editor, Fivemanage images, ox_inventory, and JG garages'
version '1.4.0'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
    'shared/images.lua',
    'shared/catalog.lua',
}

client_scripts {
    'client/callbacks.lua',
    'client/pets.lua',
    'client/oxinventory.lua',
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/framework.lua',
    'server/oxinventory.lua',
    'server/jggarages.lua',
    'server/webhooks.lua',
    'server/database.lua',
    'server/listings.lua',
    'server/callbacks.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/images/*.png',
    'html/images/*.jpg',
}

dependencies {
    'oxmysql',
    'ox_inventory',
}
