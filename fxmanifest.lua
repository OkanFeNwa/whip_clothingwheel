fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'whip_clothingwheel'
description 'Sottomenu Vestiti isolato in overlay NUI, capi a terra indossabili senza item (satellite)'
version '1.0.0'

dependency 'whip_core'

ui_page 'html/index.html'

-- Ogni .ydr generato ha bisogno di un archetype per essere spawnato per nome.
this_is_a_map 'yes'
data_file 'DLC_ITYP_REQUEST' 'stream/cw_drops.ytyp'

-- tools/ is deliberately not listed in files{}: the manual whip_core patcher is never served to NUI.
-- data/drop_models.json is server-only metadata; it is listed so LoadResourceFile can read it.
files {
    'data/drop_models.json',
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
    'server/generated_models.lua',
    'server/appearance.lua',
    'server/drops.lua',
    'server/main.lua',
}

client_scripts {
    'client/nui.lua',
    'client/main.lua',
}
