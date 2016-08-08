DAEMON_PATH = '../desktop-app'
global.STOREIT_RELATIVE_PATH = DAEMON_PATH
(require 'dotenv').config path: "#{DAEMON_PATH}/.env"

electron = require 'electron'

logger = (require '../lib/log').logger

StoreItClient = (require "../#{DAEMON_PATH}/build/client").default
settings = (require "../#{DAEMON_PATH}/build/settings").default

{app} = electron
ipc = electron.ipcMain

global.daemon = new StoreItClient
global.settings = settings

mainWin = null
tray = null

load = ->
  tray = new electron.Tray "#{__dirname}/../assets/images/icon.png"
  mainWin = new electron.BrowserWindow {width: 800, height: 600}
  # mainWin.openDevTools()

  daemon.connect().then ->
    mainWin.loadURL "file://#{__dirname}/../index.html"

  mainWin.on 'closed', -> mainWin = null

app.on 'ready', -> load()

app.on 'window-all-closed', -> app.quit() if process.platform isnt 'darwin'

app.on 'activate', -> load() unless mainWin?

oauthWin = null
oauth = (authType) ->
  oauthWin = new electron.BrowserWindow
    parent: mainWin
    modal: true
    webPreferences:
      nodeIntegration: false
  daemon.auth(authType, oauthWin.loadURL.bind(oauthWin))
    .then ->
      oauthWin.close()
    .catch (e) ->
      oauthWin.close()


ipc.on 'auth', (ev, authType) ->
  oauth(authType)
    .then -> ev.sender.send 'auth', 'done'
    .catch -> ev.sender.send 'auth', 'done'
