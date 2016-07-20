render = require 'app/render.coffee!'

template = require 'app/oauth/oauth.jade!'
require 'app/oauth/oauth.css!'

module.exports =
  run: -> render.template template
