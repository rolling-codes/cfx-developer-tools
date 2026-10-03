fx_version 'cerulean'
games { 'rdr3' }

name 'my-resource'
author 'your-name'
description 'A VORP resource'
version '1.0.0'

dependencies {
    'vorp_core',
}

shared_scripts { 'config.lua' }
client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }
