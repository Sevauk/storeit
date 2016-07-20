$ = require 'bootstrap'

module.exports =
  template: (template) ->
    container = $ '#container'
    container.empty()
    ($ template.html).appendTo(container)
