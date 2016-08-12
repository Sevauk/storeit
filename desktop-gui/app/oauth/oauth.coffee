$ = require 'bootstrap'
template = require 'app/oauth/oauth.jade!'
require 'app/oauth/oauth.css!'

ipc = (System._nodeRequire 'electron').ipcRenderer
userSettings = (require 'app/remote.coffee!') 'settings'

render = require 'app/render.coffee!'
settings = require 'app/settings/settings.coffee!'

auth = (type) -> ipc.send 'auth', type

listen = ->
  ipc.on 'auth', (ev, arg) -> settings.spawn()
  $('.login-buttons button').click ->
    target = $(this).get(0).id
    auth(target)
    wait()

wait = ->
  $('.login-buttons button').click ->

module.exports =
  spawn: ->
    authType = userSettings.getAuthType()
    render.template template unless authType?
    listen()
    auth(authType) if authType?
