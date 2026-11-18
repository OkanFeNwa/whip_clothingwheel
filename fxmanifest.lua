fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'whip_clothingwheel'
description 'Sottomenu Vestiti isolato in overlay NUI, capi a terra indossabili senza item (satellite)'
version '1.0.0'

dependency 'whip_core'

ui_page 'html/index.html'

-- tools/ is deliberately not listed in files{}: the manual whip_core patcher is never served to NUI.
files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}

shared_scripts {
    '@whip_core/lib/satellite.lua',
    'config.lua',
    'shared/slots.lua',
}

server_scripts {
    'server/appearance.lua',
    'server/drops.lua',
    'server/main.lua',
}

client_scripts {
    'client/nui.lua',
    'client/main.lua',
}
