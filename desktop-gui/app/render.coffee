$ = require 'bootstrap'

module.exports =
  template: (template) -> ($ template.html).appendTo($ '#container')
