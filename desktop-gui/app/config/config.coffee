$ = require 'bootstrap'

render = require 'app/render.coffee!'

template = require 'app/config/config.jade!'
require 'app/config/config.css!'

module.exports =
  spawn: ->
    render.template template
