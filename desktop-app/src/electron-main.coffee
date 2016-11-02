menubar = require 'menubar'
electron = require 'electron'
{app, BrowserWindow} = electron
ipc = electron.ipcMain

{logger} = (require '../lib/log')
StoreItClient = (require '../build/daemon/client').default
global.daemon = new StoreItClient
global.settings = (require '../build/daemon/settings').default
global.userFile = (require '../build/daemon/user-file').default

display = null
mainWin = null

view = menubar
  alwaysOnTop: true #TODO remove
  index: "file://#{__dirname}/../index.html?p=downloads"
  height: 500
  icon: "#{__dirname}/../assets/images/icon.png"
  tooltip: 'StoreIt'
  width: 300

loadPage = (page) ->
  unless mainWin?
    mainWin = new BrowserWindow
      width: display.size.width
      height: display.size.height
      # show: false # TODO remove
    mainWin.on 'closed', -> mainWin = null
  mainWin.loadURL "file://#{__dirname}/../index.html?p=#{page or ''}"
  mainWin.openDevTools() if OPTIONS.dev

authWin = null
createAuthWin = (url, showModal=true) ->
  logger.debug('create auth win')
  authWin = new BrowserWindow
    parent: mainWin
    modal: true
    show: showModal
    webPreferences:
      nodeIntegration: false
  authWin.on 'closed', -> authWin = null
  authWin.loadURL(url)

login = (authType, showModal=true) ->
  opts =
    type: authType
    devId: null
    win: (url) -> createAuthWin(url, showModal)
  daemon.start opts
    .then ->
      logger.debug 'done'
      loadPage 'settings'
      authWin.close()
    .catch (e) ->
      authWin.close()
      terminate e

# TODO
logout = ->
  logger.debug('GUI: logout')
  daemon.logout()

# TODO
restart = ->
  logger.debug('GUI: restart')
  daemon.restart()

tray = null
init = (p) ->
  display = electron.screen.getPrimaryDisplay()
  view.tray.setContextMenu electron.Menu.buildFromTemplate [
    {label: 'Settings', click: -> loadPage 'settings'}
    {label: 'Statistics', click: -> loadPage 'stats'} #TODO
    {label: 'Logout', click: -> logout()} #TODO
    {type: 'separator'}
    {label: 'Restart', click: -> restart()} #TODO
    {label: 'Quit', click: -> app.quit()}
  ]

  authType = settings.getAuthType()
  if authType?
    login authType, false
  else
    loadPage()

ipc.on 'auth', (ev, authType) ->
  login(authType, authType isnt 'developer')
    .then -> ev.sender.send 'auth', 'done'
    .catch -> ev.sender.send 'auth', 'done'

ipc.on 'restart', (ev) -> restart()

terminate = (err) ->
  console.error 'Fatal error:', err
  process.exit 1

process.on 'error', terminate
process.on 'uncaughtException', terminate

exports.run = (program) ->
  global.OPTIONS = program
  # view.on 'ready', -> init()
  view.on 'ready', -> init()
  view.on 'after-create-window', ->
    # view.window.openDevTools() if OPTIONS.dev # TODO remove
  app.on 'activate', -> init() unless mainWin?
