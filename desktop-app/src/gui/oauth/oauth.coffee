$ = require 'bootstrap'
Page = require '../page.coffee!'

ipc = electron.ipcRenderer

template = require './oauth.jade!'
require './oauth.css!'
TITLE = 'Login'

module.exports = class OAuthView extends Page
  constructor: ->
    super TITLE, template

  auth: (type) ->
    ipc.send 'auth', type

  listen: ->
    $('.login-buttons button').click (ev) =>
      @auth(ev.target.id)
      @wait()

  wait: ->
    $('.login-buttons button').click ->

  render: ->
    super
    @listen()
