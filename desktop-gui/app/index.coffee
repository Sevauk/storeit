$ = require 'bootstrap'
require 'bootstrap/css/bootstrap.css!'

template = require 'app/oauth.jade!'

$ ->
  ($ template.html).appendTo($ document.body)
