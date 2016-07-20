$ = require 'bootstrap'

ipc = (System._nodeRequire 'electron').ipcRenderer

render = require 'app/render.coffee!'

template = require 'app/oauth/oauth.jade!'
require 'app/oauth/oauth.css!'

config = require 'app/config/config.coffee!'

listen = ->
  $('.login-buttons button').click ->
    target = $(this).get(0).id
    ipc.on 'auth', (ev, arg) -> config.spawn()
    ipc.send 'auth', target
    wait()

wait = ->
  console.log 'here'
  $('.login-buttons button').click ->

module.exports =
  spawn: ->
    render.template template
    listen()
