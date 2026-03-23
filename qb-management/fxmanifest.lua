fx_version 'cerulean'
game 'gta5'

description 'L2S V6 PACK || Editied By : @l2sdev @2025 || https://l2s.dev'
author 'L2S DEV TEAM '
version '2.0.0'

client_scripts {
    'config.lua',
    'client/*.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'config.lua',
    'server/*.lua'
}

server_exports {
    'AddMoney',
    'AddGangMoney',
    'RemoveMoney',
    'RemoveGangMoney',
    'GetAccount',
    'GetGangAccount',
}

lua54 'yes'
