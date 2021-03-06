window.electron = (System._nodeRequire 'electron')

$ = require 'bootstrap'
require 'bootstrap/css/bootstrap.css!'
queryString = require 'query-string'

template = require './app.jade!'
require './app.css!'

ipc = electron.ipcRenderer

pages =
 downloads: require './downloads/downloads.coffee!'
 oauth: require './oauth/oauth.coffee!'
 settings: require './settings/settings.coffee!'

$ ->
  ($ template.html).appendTo($ document.body)
  ipc.on 'load-page', (ev, name) ->
    console.log 'page:', name
    if pages[name]?
      page = new pages[name]
      page.render()

  console.log 'ready'
  ipc.send('renderer-ready', true)

    # load dynamically
    # page = params.p
    # System.import("./src/gui/#{params.p}/#{params.p}.coffee!")
    #   .then (page) -> page.spawn()
