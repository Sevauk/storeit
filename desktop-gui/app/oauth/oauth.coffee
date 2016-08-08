$ = require 'bootstrap'

ipc = (System._nodeRequire 'electron').ipcRenderer

settings = (require 'app/remote.coffee!') 'settings'

render = require 'app/render.coffee!'

template = require 'app/oauth/oauth.jade!'
require 'app/oauth/oauth.css!'

config = require 'app/config/config.coffee!'

auth = (type) -> ipc.send 'auth', type

listen = ->
  ipc.on 'auth', (ev, arg) -> config.spawn()
  $('.login-buttons button').click ->
    target = $(this).get(0).id
    auth(target)
    wait()

wait = ->
  $('.login-buttons button').click ->

module.exports =
  spawn: ->
    authType = settings.getAuthType()
    render.template template unless authType?
    listen()
    auth(authType) if authType?
