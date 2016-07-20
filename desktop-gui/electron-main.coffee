DAEMON_PATH = '../desktop-app'
global.STOREIT_RELATIVE_PATH = DAEMON_PATH
(require 'dotenv').config path: "#{DAEMON_PATH}/.env"

electron = require 'electron'

logger = (require '../lib/log').logger

StoreItClient = (require "../#{DAEMON_PATH}/build/client").default

{app} = electron
ipc = electron.ipcMain

global.daemon = new StoreItClient
win = null
tray = null

load = ->
  tray = new electron.Tray "#{__dirname}/../assets/images/icon.png"
  win = new electron.BrowserWindow {width: 800, height: 600}

  daemon.connect().then ->
    ipc.on 'auth', (ev, authType) ->
      daemon.auth authType
    win.loadURL "file://#{__dirname}/../index.html"

  win.on 'closed', -> win = null

app.on 'ready', -> load()

app.on 'window-all-closed', -> app.quit() if process.platform isnt 'darwin'

app.on 'activate', -> load() unless win?
