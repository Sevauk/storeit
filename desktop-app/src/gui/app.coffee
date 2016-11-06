$ = require 'bootstrap'
require 'bootstrap/css/bootstrap.css!'
queryString = require 'query-string'

template = require './app.jade!'
require './app.css!'

pages =
 downloads: require './downloads/downloads.coffee!'
 oauth: require './oauth/oauth.coffee!'
 settings: require './settings/settings.coffee!'

console.log('app loaded')
$ ->
  ($ template.html).appendTo($ document.body)
  params = queryString.parse location.search
  if params.p?
    pages[params.p].spawn()
    # page = params.p
    # System.import("./src/gui/#{params.p}/#{params.p}.coffee!")
    #   .then (page) -> page.spawn()
