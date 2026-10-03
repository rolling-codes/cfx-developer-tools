fx_version 'cerulean'
games { 'gta5' }

name 'playtime-tracker'
author 'cfx-developer-tools'
description 'Track and display player playtime using oxmysql'
version '1.0.0'

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

dependencies {
    'oxmysql',
}
