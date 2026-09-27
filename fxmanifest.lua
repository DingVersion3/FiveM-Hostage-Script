fx_version 'cerulean'
game 'gta5'
author 'Ding'
description 'Player hostage interactions, custody handover and persistent protection'
version '1.0.0'
dependency '/onesync'
shared_script 'config.lua'
server_scripts { 'server/bridge.lua', 'server/main.lua' }
client_script 'client/main.lua'
ui_page 'web/dist/index.html'
files { 'web/dist/index.html', 'web/dist/assets/*' }
