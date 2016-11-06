$ = require 'bootstrap'

module.exports = class Page
  constructor: (@title, @template) ->
  render: ->
    container = $ '#container #page-content'
    container.empty()
    ($ '#title').text(@title)
    ($ @template.html).appendTo(container)
