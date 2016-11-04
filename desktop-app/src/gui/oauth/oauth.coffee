$ = require 'bootstrap'
template = require './oauth.jade!'
require './oauth.css!'

ipc = (System._nodeRequire 'electron').ipcRenderer
userSettings = (require '../remote.coffee!') 'settings'

render = require '../render.coffee!'
settings = require '../settings/settings.coffee!'

auth = (type) ->
  ipc.send 'auth', type

listen = ->
  ipc.on 'auth', (ev, arg) -> settings.spawn()
  $('.login-buttons button').click ->
    target = $(this).get(0).id
    auth(target)
    wait()

wait = ->
  $('.login-buttons button').click ->

console.log 'oauth'

module.exports =
  spawn: ->
    authType = userSettings.getAuthType()
    render.template template unless authType?
    listen()
