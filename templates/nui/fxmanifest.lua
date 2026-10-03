fx_version 'cerulean'
games { 'gta5' }

name 'my-nui-resource'
author 'your-name'
description 'A FiveM resource with NUI'
version '1.0.0'

shared_scripts { 'config.lua' }
client_scripts { 'client/*.lua' }
server_scripts { 'server/*.lua' }

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/app.js',
}
