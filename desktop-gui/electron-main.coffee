DAEMON_PATH = '../desktop-app'
global.STOREIT_RELATIVE_PATH = DAEMON_PATH
(require 'dotenv').config path: "#{DAEMON_PATH}/.env"

electron = require 'electron'

logger = (require '../lib/log').logger

StoreItClient = (require "../#{DAEMON_PATH}/build/client").default

{app} = electron
ipc = electron.ipcMain

global.daemon = new StoreItClient
mainWin = null
tray = null

load = ->
  tray = new electron.Tray "#{__dirname}/../assets/images/icon.png"
  mainWin = new electron.BrowserWindow {width: 800, height: 600}
  mainWin.openDevTools()

  daemon.connect().then ->
    mainWin.loadURL "file://#{__dirname}/../index.html"

  mainWin.on 'closed', -> mainWin = null

app.on 'ready', -> load()

app.on 'window-all-closed', -> app.quit() if process.platform isnt 'darwin'

app.on 'activate', -> load() unless mainWin?

oauthWin = null
ipc.on 'auth', (ev, authType) ->
  oauthWin = new electron.BrowserWindow
    parent: mainWin
    modal: true
    webPreferences:
      nodeIntegration: false
  daemon.auth(authType, oauthWin.loadURL.bind(oauthWin))
    .then ->
      oauthWin.close()
      ev.sender.send 'auth', 'done'
    .catch (e) ->
      oauthWin.close()
      ev.sender.send 'auth', 'done' # FIXME: workaround
