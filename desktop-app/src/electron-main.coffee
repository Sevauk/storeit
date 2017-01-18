menubar = require 'menubar'
electron = require 'electron'
{app, BrowserWindow} = electron
ipc = electron.ipcMain

{logger} = (require '../lib/log')
StoreItClient = (require '../build/daemon/client').default
global.daemon = new StoreItClient
global.settings = (require '../build/daemon/settings').default
global.userFile = (require '../build/daemon/user-file').default

APP_NAME = 'StoreIt'
APP_ICON = "#{__dirname}/../assets/images/icon.png"
APP_INDEX = "file://#{__dirname}/../index.html"

view = menubar
  # alwaysOnTop: true
  index: APP_INDEX
  height: 500
  icon: APP_ICON
  preloadWindow: true
  tooltip: 'StoreIt'
  width: 300

currPage = null
loadPage = (page) ->
  unless currPage is page
    currPage = page
    view.window.webContents.send 'load-page', page
  view.showWindow()
  view.window.openDevTools() if OPTIONS.dev

authWin = null
createAuthWin = (url, showModal=true) ->
  authWin = new BrowserWindow
    icon: APP_ICON
    parent: view.window
    modal: true
    show: false
    title: "#{APP_NAME} - Authentication"
    webPreferences:
      nodeIntegration: false
  authWin.on 'closed', -> authWin = null
  authWin.loadURL(url)
  authWin.once 'ready-to-show', -> authWin.show() if authWin? # and showModal

login = (authType, showModal=true) ->
  logger.debug('[GUI] trigger login')
  opts =
    type: 'developer'
    # type: authType
    devId: null
    win: (url) -> createAuthWin(url, showModal)
  daemon.start opts
    .then ->
      loadPage 'settings'
      authWin.close() if authWin?
    .catch (e) ->
      authWin.close() if authWin?
      terminate e

logout = ->
  logger.debug('[GUI] logout')
  daemon.logout()
  loadPage 'oauth'

# TODO
restart = ->
  logger.debug('[GUI] restart')
  daemon.restart()

initApp = (p) ->
  ipc.on 'auth', (ev, authType) ->
    login(authType, authType isnt 'developer')
      .then -> ev.sender.send 'auth', 'done'
      .catch -> ev.sender.send 'auth', 'done'
  ipc.on 'restart', (ev) -> restart()
  menu = electron.Menu.buildFromTemplate [
    {label: 'Preferences', click: -> loadPage 'settings'}
    {label: 'Account', click: -> loadPage 'account'}
    {label: 'Downloads', click: -> loadPage 'downloads'}
    # {label: 'OAuth', click: -> loadPage 'oauth'} # only for debug
    {label: 'Logout', click: -> logout()}
    {type: 'separator'}
    {label: 'Restart', click: -> restart()}
    {label: 'Quit', click: -> app.quit()}
  ]
  view.tray.on 'right-click', -> view.tray.popUpContextMenu menu
  ipc.on 'renderer-ready', ->
    authType = settings.getAuthType()
    if authType?
      login authType, false
    else
      loadPage 'oauth'

terminate = (err) ->
  logger.error '[GUI] Fatal error:', err
  process.exit 1

process.on 'error', terminate
process.on 'uncaughtException', terminate

exports.run = (program) ->
  global.OPTIONS = program
  view.on 'ready', initApp

  view.on 'after-create-window', ->
    view.window.setTitle APP_NAME
    view.window.setSkipTaskbar true
    # view.window.openDevTools() if OPTIONS.dev # TODO remove

  # this prevent default: quit on when all windows are closed
  app.on 'window-all-closed', ->
