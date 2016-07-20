$ = require 'bootstrap'

ipc = (System._nodeRequire 'electron').ipcRenderer

render = require 'app/render.coffee!'

template = require 'app/oauth/oauth.jade!'
require 'app/oauth/oauth.css!'

module.exports =
  run: ->
    render.template template
    $('.login-buttons button').click ->
      target = $(this).get(0).id
      ipc.send 'auth', target
