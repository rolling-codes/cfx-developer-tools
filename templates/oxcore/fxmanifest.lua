fx_version 'cerulean'
games { 'gta5' }

name 'my-resource'
author 'your-name'
description 'An ox_core resource'
version '1.0.0'

dependencies {
    'ox_core',
    'ox_lib',
}

shared_scripts { 'config.lua' }
client_scripts { 'client/*.lua' }
server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/*.lua',
}
