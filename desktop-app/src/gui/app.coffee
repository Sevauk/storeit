$ = require 'bootstrap'
require 'bootstrap/css/bootstrap.css!'
queryString = require 'query-string'

template = require './app.jade!'
require './app.css!'

# pages =
#  downloads: require './downloads/downloads.coffee!'
#  oauth: require './oauth/oauth.coffee!'
#  settings: require './settings/settings.coffee!'
#
$ ->
  ($ template.html).appendTo($ document.body)
  params = queryString.parse location.search
  if params.p?
    page = params.p
    System.import("./#{params.p}/#{params.p}.coffee!")
      .then (page) -> page.spawn()
