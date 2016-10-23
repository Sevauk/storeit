electron = require 'electron'
{app} = electron
ipc = electron.ipcMain

{logger} = (require '../lib/log')
StoreItClient = (require '../build/daemon/client').default
global.settings = (require '../build/daemon/settings').default

display = null
mainWin = null
loadPage = (page) ->
  unless mainWin?
    mainWin = new electron.BrowserWindow
      width: display.size.width
      height: display.size.height
    mainWin.on 'closed', -> mainWin = null
  mainWin.loadURL "file://#{__dirname}/../index.html?p=#{page or ''}"
  mainWin.openDevTools() if OPTIONS.dev

authWin = null
auth = (authType) ->
  authWin = new electron.BrowserWindow
    parent: mainWin
    modal: true
    show: settings.getAuthType() == null
    webPreferences:
      nodeIntegration: false
  authWin.on 'closed', -> authWin = null
  opts =
    type: authType
    devId: null # TODO
    authWin: authWin.loadURL.bind(authWin)
  daemon.start opts
    .then -> authWin.close()
    .catch (e) -> authWin.close()
    .then -> daemon.start()
    .then -> loadPage 'settings'

tray = null
init = ->
  display = electron.screen.getPrimaryDisplay()
  tray = new electron.Tray "#{__dirname}/../assets/images/icon.png"
  tray.setToolTip 'StoreIt'

  tray.setContextMenu electron.Menu.buildFromTemplate [
    {label: 'Settings', click: -> loadPage 'settings'}
    {label: 'Statistics', click: -> loadPage 'stats'} #TODO
    {label: 'Logout', click: -> daemon.logout()} #TODO
    {type: 'separator'}
    {label: 'Restart', click: -> daemon.restart()} #TODO
    {label: 'Quit', click: -> app.quit()}
  ]
  authType = settings.getAuthType()
  if authType?
    auth(authType)
  else
    loadPage()

ipc.on 'auth', (ev, authType) ->
  # auth(authType)
  #   .then -> ev.sender.send 'auth', 'done'
  #   .catch -> ev.sender.send 'auth', 'done'

ipc.on 'reload', (ev) -> # daemon.restart() #TODO

terminate = (err) ->
  console.error err
  process.exit 1

process.on 'error', terminate
process.on 'uncaughtException', terminate

exports.run = (program) ->
  global.OPTIONS = program
  global.daemon = new StoreItClient
  app.on 'ready', -> init()
  app.on 'activate', -> init() unless mainWin?
