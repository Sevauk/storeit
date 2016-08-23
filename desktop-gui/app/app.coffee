$ = require 'bootstrap'
require 'bootstrap/css/bootstrap.css!'
queryString = require 'query-string'

template = require 'app/app.jade!'
require 'app/app.css!'

pages =
 oauth: require 'app/oauth/oauth.coffee!'
 settings: require 'app/settings/settings.coffee!'

$ ->
  ($ template.html).appendTo($ document.body)
  params = queryString.parse location.search
  pages[params.p or 'oauth'].spawn()
