$ = require 'bootstrap'
template = require './settings.jade!'
require './settings.css!'

render = require '../render.coffee!'
remote = (System._nodeRequire 'electron').remote

ipc = remote.ipcRenderer
{dialog} = remote
{BrowserWindow} = remote

userSettings = (require '../remote.coffee!') 'settings'

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

  win = remote.getCurrentWindow()
  $('#storeit-dir-change').click (ev) ->
    ev.preventDefault()
    dialog.showOpenDialog win, properties: ['openDirectory'], (path) ->
      $('#storeit-dir').val(path) if path?

  $('#storeit-validate').click (ev) ->
    ev.preventDefault()
    save()

  $('#storeit-reset').click (ev) ->
    ev.preventDefault()
    reset()
  return


module.exports =
  spawn: ->
    render.template template
    do init
