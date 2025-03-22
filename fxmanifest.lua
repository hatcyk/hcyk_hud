fx_version 'cerulean'
game 'gta5'

author 'Hatcyk'
description 'HudSystem'
version '2.0.0'

lua54 'yes'
use_fxv2_oal 'yes'

ui_page 'html/index.html'

client_scripts {
    'config.lua',
    'modules/utils.lua',
    'modules/postals.lua',
    'modules/seatbelt.lua',
    'modules/cruise.lua',
    'modules/vehicle.lua',
    'modules/hud.lua',
    'client.lua'
}

server_scripts {
    'server.lua',
    'config.lua'
}

files {
    'html/index.html',
    'html/styles.css',
    'html/app.js',
}

shared_script '@es_extended/imports.lua'