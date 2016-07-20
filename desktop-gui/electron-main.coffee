DAEMON_PATH = '../desktop-app'
(require 'dotenv').config path: "#{DAEMON_PATH}/.env"

electron = require 'electron'

logger = (require '../lib/log').logger

StoreItClient = (require "../#{DAEMON_PATH}/build/client").default

{app} = electron

daemon = new StoreItClient
win = null

init = -> daemon.connect()

load = ->
  win = new electron.BrowserWindow {width: 800, height: 600}

  init()
    .then -> win.loadURL "file://#{__dirname}/../index.html"

  win.on 'closed', -> win = null

app.on 'ready', -> load()

app.on 'window-all-closed', -> app.quit() if process.platform isnt 'darwin'

app.on 'activate', -> load() unless win?
