fx_version 'cerulean'
games { 'gta5' }

name 'secure-shop'
author 'cfx-developer-tools'
description 'Server-authoritative shop — never trusts client-sent price or item data'
version '1.0.0'

shared_scripts { 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts { 'server/main.lua' }
