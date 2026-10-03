fx_version 'cerulean'
games { 'gta5' }

name 'my-resource'
author 'your-name'
description 'An ESX resource'
version '1.0.0'

dependencies {
    'es_extended',
}

shared_scripts { 'config.lua' }
client_scripts { 'client/*.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}
