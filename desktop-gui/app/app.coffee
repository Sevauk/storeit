$ = require 'bootstrap'
require 'bootstrap/css/bootstrap.css!'
window.daemon = (require 'app/remote.coffee!')('daemon')

template = require 'app/app.jade!'
require 'app/app.css!'

oauth = require 'app/oauth/oauth.coffee!'

$ ->
  ($ template.html).appendTo($ document.body)
  oauth.run()
