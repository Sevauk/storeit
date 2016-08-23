$ = require 'bootstrap'
template = require 'app/settings/settings.jade!'
require 'app/settings/settings.css!'

ipc = (System._nodeRequire 'electron').ipcRenderer
userSettings = (require 'app/remote.coffee!') 'settings'

render = require 'app/render.coffee!'

save = ->
  userSettings.setFolderPath $('#storeit-dir').val()
  userSettings.setAllocated $('storeit-space').val()
  userSettings.setBandwidth $('storeit-bandwidth').val()
  userSettings.save()
  ipc.send 'reload'

reset = ->
  userSettings.reset()
  ipc.send 'reload'

init = ->
  $('#storeit-dir').val userSettings.getFolderPath()
  $('#storeit-space').val userSettings.getAllocated()
  $('#storeit-bandwidth').val userSettings.getBandwidth()


module.exports =
  spawn: ->
    render.template template
    do init
    $('#storeit-validate').click -> save()
    $('#storeit-reset').click -> reset()
