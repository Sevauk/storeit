electron = require 'electron'

shell = require 'shelljs'
logger = (require '../lib/log').logger

{app} = electron
win = null

init = ->
  # if shell.exec('npm --prefix ../desktop-app start').code isnt 0
  #   logger.error 'Error: could not start daemon'
  # else
  #   logger.info 'StoreIt daemon started'

load = ->
  win = new electron.BrowserWindow {width: 800, height: 600}

  init()
  win.loadURL "file://#{__dirname}/../index.html"
  win.on 'closed', -> win = null

app.on 'ready', -> load()

app.on 'window-all-closed', -> app.quit() if process.platform isnt 'darwin'

app.on 'activate', -> load() unless win?
