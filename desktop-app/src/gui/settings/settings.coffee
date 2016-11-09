$ = require 'bootstrap'
Page = require '../page.coffee!'
remote = electron.remote

{dialog} = remote
win = remote.getCurrentWindow()

userSettings = remote.getGlobal 'settings'

template = require './settings.jade!'
require './settings.css!'
TITLE = 'Preferences'

module.exports = class SettingsView extends Page
  constructor: ->
    super TITLE, template

  render: ->
    super
    @init()

  save: ->
    userSettings.setStoreDir $('#storeit-dir').val()
    userSettings.setAllocated $('storeit-space').val()
    userSettings.setBandwidth $('storeit-bandwidth').val()
    userSettings.save()
    ipc.send 'reload'

  reset: ->
    userSettings.reset()
    ipc.send 'reload'

  init: ->
    $('#storeit-dir').val userSettings.getStoreDir()
    $('#storeit-space').val userSettings.getAllocated()
    $('#storeit-bandwidth').val userSettings.getBandwidth()

    $('#storeit-dir-change').click (ev) ->
      ev.preventDefault()
      dialog.showOpenDialog win, properties: ['openDirectory'], (path) ->
        $('#storeit-dir').val(path) if path?

    $('#storeit-validate').click (ev) ->
      ev.preventDefault()
      @save()

    $('#storeit-reset').click (ev) ->
      ev.preventDefault()
      @reset()
    return
