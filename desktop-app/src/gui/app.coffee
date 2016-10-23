$ = require 'bootstrap'
require 'bootstrap/css/bootstrap.css!'
queryString = require 'query-string'

template = require './app.jade!'
require './app.css!'

pages =
 downloads: require './downloads/downloads.coffee!'
 oauth: require './oauth/oauth.coffee!'
 settings: require './settings/settings.coffee!'

$ ->
  ($ template.html).appendTo($ document.body)
  params = queryString.parse location.search
  pages[params.p or 'oauth'].spawn()
