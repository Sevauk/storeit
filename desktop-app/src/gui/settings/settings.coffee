$ = require 'bootstrap'
template = require './settings.jade!'
require './settings.css!'

ipc = (System._nodeRequire 'electron').ipcRenderer
userSettings = (require '../remote.coffee!') 'settings'

render = require '../render.coffee!'

save = ->
  userSettings.setStoreDir $('#storeit-dir').val()
  userSettings.setAllocated $('storeit-space').val()
  userSettings.setBandwidth $('storeit-bandwidth').val()
  userSettings.save()
  ipc.send 'reload'

reset = ->
  userSettings.reset()
  ipc.send 'reload'

init = ->
  $('#storeit-dir').val userSettings.getStoreDir()
  $('#storeit-space').val userSettings.getAllocated()
  $('#storeit-bandwidth').val userSettings.getBandwidth()


module.exports =
  spawn: ->
    render.template template
    do init
    $('#storeit-validate').click -> save()
    $('#storeit-reset').click -> reset()
