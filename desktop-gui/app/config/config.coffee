$ = require 'bootstrap'
template = require 'app/config/config.jade!'
require 'app/config/config.css!'

ipc = (System._nodeRequire 'electron').ipcRenderer
settings = (require 'app/remote.coffee!') 'settings'

render = require 'app/render.coffee!'

save = ->
  settings.setFolderPath $('#storeit-dir').val()
  settings.setAllocated $('storeit-space').val()
  settings.setBandwidth $('storeit-bandwidth').val()
  settings.save()
  ipc.send 'reload'

reset = ->
  settings.reset()
  ipc.send 'reload'

init = ->
  $('#storeit-dir').val settings.getFolderPath()
  $('#storeit-space').val settings.getAllocated()
  $('#storeit-bandwidth').val settings.getBandwidth()


module.exports =
  spawn: ->
    render.template template
    do init
    $('#storeit-validate').click -> save()
    $('#storeit-reset').click -> reset()
