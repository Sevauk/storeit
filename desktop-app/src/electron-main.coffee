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
  # alwaysOnTop: true #TODO remove
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
    view.window.webContents.send 'load', page
  view.showWindow()
  # view.window.openDevTools() if OPTIONS.dev

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

# TODO
logout = ->
  logger.debug('GUI: logout')
  daemon.logout()

# TODO
restart = ->
  logger.debug('GUI: restart')
  daemon.restart()

init = (p) ->
  menu = electron.Menu.buildFromTemplate [
    {label: 'Preferences', click: -> loadPage 'settings'}
    {label: 'Downloads', click: -> loadPage 'downloads'}
    # {label: 'OAuth', click: -> loadPage 'oauth'} # only for debug
    {label: 'Statistics', click: -> loadPage 'stats'} #TODO
    {label: 'Logout', click: -> logout()} #TODO
    {type: 'separator'}
    {label: 'Restart', click: -> restart()} #TODO
    {label: 'Quit', click: -> app.quit()}
  ]
  view.tray.setContextMenu menu

  authType = settings.getAuthType()
  if authType?
    login authType, false
  else
    loadPage 'oauth'

ipc.on 'auth', (ev, authType) ->
  login(authType, authType isnt 'developer')
    .then -> ev.sender.send 'auth', 'done'
    .catch -> ev.sender.send 'auth', 'done'

ipc.on 'restart', (ev) -> restart()

terminate = (err) ->
  logger.error 'Fatal error:', err
  process.exit 1

process.on 'error', terminate
process.on 'uncaughtException', terminate

exports.run = (program) ->
  global.OPTIONS = program
  view.on 'ready', -> init()
  view.on 'after-create-window', ->
    view.window.setTitle APP_NAME
    view.window.setSkipTaskbar true
    # view.window.openDevTools() if OPTIONS.dev # TODO remove

  # I have no idea what's the point of this
  # app.on 'activate', -> init() unless view.window?

  # this prevent default: quit on when all windows are closed
  app.on 'window-all-closed', ->
