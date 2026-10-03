fx_version 'cerulean'
games { 'gta5' }

name 'my-resource'
author 'your-name'
description 'A Qbox resource'
version '1.0.0'

dependencies {
    'qbx_core',
    'ox_lib',
}

shared_scripts { 'config.lua' }
client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }
