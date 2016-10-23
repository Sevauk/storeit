$ = require 'bootstrap'
template = require './downloads.jade!'
require './downloads.css!'

render = require '../render.coffee!'
userFile = (require '../remote.coffee!') 'userFile'

shell = (System._nodeRequire 'electron').shell
md5 = require('md5')

itemsCount = 0

makeItem = (id, file) -> """
  <div class="row item">
    <div class="media" id="#{id}">
      <div class="media-left">
        <img class="media-object" src="" />
      </div>
      <div class="media-body">
        <h4 class="media-heading">#{file.path}</h4>
        <span class="curr-size">0 Bytes</span>
        <span> of </span>
        <span class="total-size">0 Bytes</span>
        <div class="progress">
          <div class="
              progress-bar progress-bar-striped progress-bar-success
              active"
            role="progressbar" aria-valuenow="0"
            aria-valuemin="0" aria-valuemax="100" style="width:0%">
            0%
          </div>
        </div>
        <div class="buttons" style="display: none"></div>
      </div>
    </div>
  </div>
"""

readableSize = (bytes) ->
  sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
  if (bytes is 0)
    return '0 Bytes'
  i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)))
  return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + sizes[i]


createItem = (id, file) ->
  item = makeItem(id, file)
  $(item).prependTo($('#list'))

showInFolder = (filePath) ->
  shell.showItemInFolder userFile.absolutePath(filePath)

finishDownload = (id, file) ->
  $("##{id} .progress-bar").removeClass 'active'
  $("##{id} .progress-bar").removeClass 'progress-bar-striped'
  $("##{id} .media-body .buttons")
    .append("""
      <button class="btn btn-default show-in">Show in folder</button>
      <button class="btn btn-default remove">Remove from list</button>
    """)
  $("##{id} .media-body .show-in").click(-> showInFolder(file.path))
  show = -> $("##{id} .media-body .buttons").show()
  hide = -> $("##{id} .media-body .buttons").hide()
  remove = -> $("##{id}").parent().remove()
  $("##{id}").hover(show, hide)
  $("##{id} .remove").click(remove)

updateStatus = (percent, file) ->
  id = md5(file.path)
  elem = $("##{id}")
  createItem(id, file) unless elem.length
  $("##{id} .progress-bar").width("#{percent}%")
  $("##{id} .progress-bar").text("#{percent}%")
  currSize = file.size * (percent / 100)
  $("##{id} .curr-size").text(readableSize(currSize))
  $("##{id} .total-size").text(readableSize(file.size))
  finishDownload(id, file) if percent is 100

module.exports =
  spawn: ->
    $('body').addClass('menu_box')
    render.template template
    file = path: '/foo', size: 500
    updateStatus 10, file
    updateStatus 62, path: '/bar', size: 300
    updateStatus 100, path: '/toto', size: 50
    setTimeout((-> updateStatus(23, file)), 2000)
    setTimeout((-> updateStatus(58, file)), 3000)
    setTimeout((-> updateStatus(77, file)), 4000)
    setTimeout((-> updateStatus(91, file)), 6000)
    setTimeout((-> updateStatus(100, file)), 6500)
