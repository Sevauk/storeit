$ = require 'bootstrap'
Page = require '../page.coffee!'

userFile = electron.remote.getGlobal 'userFile'
daemon = electron.remote.getGlobal 'daemon'

shell = electron.shell
md5 = require('md5')

template = require './downloads.jade!'
require './downloads.css!'
TITLE = 'Downloads'

URL = 'https://raw.githubusercontent.com/teambox/Free-file-icons/master/48px'
window.DEFAULT_IMG = "#{URL}/_blank.png"
fileExt = (file) -> file.substr(file.lastIndexOf('.') + 1)

SIZES = ['Bytes', 'KB', 'MB', 'GB', 'TB']
readableSize = (bytes) ->
  if (bytes is 0)
    return '0 Bytes'
  i = parseInt(Math.floor(Math.log(bytes) / Math.log(1024)))
  return Math.round(bytes / Math.pow(1024, i), 2) + ' ' + SIZES[i]

module.exports = class DownloadsView extends Page
  constructor: ->
    super TITLE, template
    @itemsCount = 0

  render: ->
    super template
    daemon.setProgressHandler(=> @updateStatus())
    @mock()

  showInFolder: (filePath) ->
    shell.showItemInFolder userFile.absolutePath(filePath)

  updateStatus: (percent, file) ->
    id = md5(file.path)
    elem = $("##{id}")
    unless elem.length
      item = @createItem(id, file)
      ($ item).prependTo($('#downloads'))

    $("##{id} .progress-bar").width("#{percent}%")
    $("##{id} .progress-bar").text("#{percent}%")
    currSize = file.size * (percent / 100)
    $("##{id} .curr-size").text(readableSize(currSize))
    $("##{id} .total-size").text(readableSize(file.size))
    @finishDownload(id, file) if percent is 100

  finishDownload: (id, file) ->
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

  createItem: (id, file) -> """
    <div class="row item">
      <div class="media" id="#{id}">
        <div class="media-left">
          <img class="media-object"
          src="#{URL}/#{fileExt(file.path)}.png"
          onerror="if (this.src != DEFAULT_IMG) this.src=DEFAULT_IMG"
          />
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

  mock: ->
    file = path: '/foo.pdf', size: 500
    @updateStatus 10, file
    @updateStatus 62, path: '/bar.xyz', size: 300
    @updateStatus 100, path: '/toto.mp3', size: 50
    setTimeout((=> @updateStatus(23, file)), 2000)
    setTimeout((=> @updateStatus(58, file)), 3000)
    setTimeout((=> @updateStatus(77, file)), 4000)
    setTimeout((=> @updateStatus(91, file)), 6000)
    setTimeout((=> @updateStatus(100, file)), 6500)
