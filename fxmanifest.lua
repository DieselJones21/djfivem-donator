fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'dj-donator'
author 'DieselJones21'
description 'Rebel Coins donator store with vehicles, weapons, pets, exclusives, and admin tools'
version '1.0.0'

shared_scripts {
    'config.lua',
    'shared/locale.lua',
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
    'server/webhooks.lua',
    'server/database.lua',
    'server/callbacks.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
    'html/images/*.png',
}

dependencies {
    'oxmysql',
    'ox_inventory',
}
