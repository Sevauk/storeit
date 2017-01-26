import WebSocket from 'ws'
import MultiProgress from 'multi-progress'

import {FacebookService, GoogleService} from './oauth'
import userFile from './user-file.js'

import StoreitClient from '../../lib/client'
import logger from '../../lib/log'
import Watcher from './watcher'
import IPFSNode from './ipfs'
import settings from './settings'

const progressBar = new MultiProgress()

const authTypes = {
  'facebook': 'fb',
  'google': 'gg'
}

export default class DesktopClient extends StoreitClient {

  constructor() {
    super((...args) => new WebSocket(...args))

    this.ipfs = new IPFSNode()
    this.authSettings = {}
    const ignored = userFile.storePath(settings.getHostDir())
    this.fsWatcher = new Watcher(settings.getStoreDir(), ignored,
      (ev) => this.getFsEvent(ev))
    this.progressBars = new Map()
    this.progressHandler = this.asciiProgressBar.bind(this)
  }

  start(opts={}) {
    this.running = true
    logger.info('[STATUS] starting up daemon')
    this.authSettings.type = opts.type || this.authSettings.type
    this.authSettings.devId = opts.devId || this.authSettings.devId || 0
    this.authSettings.win = opts.win || this.authSettings.win

    return this.ipfs.connect()
      .then(() => this.connect())
      .then(() => this.fsWatcher.start())
      .then(() => logger.info('[STATUS] daemon is ready'))
  }

  stop() {
    this.running = false
    logger.info('[STATUS] attempting to gracefully shut down daemon')
    return this.fsWatcher.stop()
      .then(() => this.close())
      .then(() => this.ipfs.close())
      .then(() => logger.info('[STATUS] daemon stopped'))
  }

  restart() {
    return this.stop()
      .then(() => this.start())
  }

  auth() {
    this.logging = true

    this.service = null
    switch (this.authSettings.type) {
      case 'facebook':
        this.service = new FacebookService()
        break
      case 'google':
        this.service = new GoogleService()
        break
      case 'st':
        return this.login('john.doe@gmail.com', 'physics') // TODO: use tokens returned by our backend
      case 'developer':
        return this.developer()
      default:
        return Promise.reject('invalid authentication type')
    }

    logger.info(`[AUTH] login with ${this.authSettings.type} OAuth`)

    logger.debug('[AUTH] settings:', logger.toJson(this.authSettings))
    return this.service.oauth(this.authSettings.win)
      .tap(() => this.service = null)
      .then(tokens => this.reqJoin({type: authTypes[this.authSettings.type], accessToken: tokens.access_token}))
      .catch(e => {
        this.cancelAuth()
        logger.error(`[AUTH] login failed ${e}`)
        throw new Error(e)
      })
  }

  cancelAuth() {
    if (this.service != null) {
      this.service.stopHttpServer()
      this.service = null
    }
  }

  developer(devId='') {
    logger.info('[AUTH] login as developer')
    return this.reqJoin({type: 'gg', accessToken: `developer${devId}`})
  }

  login(email, password) {
    logger.info(`logining with ${'StoreIt'}`)
    this.request('AUTH', {email, password})
      .then(resp => {
        logger.debug(`got token ${resp.accessToken}`)
        return this.reqJoin({type: 'st', accessToken: resp.accessToken})
      })

  }

  logout() {
    this.stop()
    settings.resetTokens()
    settings.save()
  }

  connect() {
    if (!this.running) {
      // QUICKFIX never resolve to cancel reconnect on logout
      return new Promise(() => {})
    }

    return super.connect()
      .catch((e) => {
        logger.debug(`connect error: ${logger.toJson(e)}`)
        return this.reconnect()
      })
      .then(() => this.auth(this.authSettings))
  }

  reloadSettings() {
    // TODO
    settings.reload()
  }

  addFilesUnknownByServ(home) {
    return userFile.getUnknownFiles(home)
      // .each(filePath => this.sendFADD(filePath)) // TODO
  }

  syncDir(file) {
    return userFile.dirCreate(file.path)
      .tap(() => logger.info(`[DIR-SYNC] ${file.path}`))
      .then(() => this.recvFADD({parameters: {files: file.files}}, false))
      .tap(() => logger.info(`[DIR-SYNC:end] ${file.path} `))
  }

  syncFile(file) {
    logger.info(`[SYNC:start] ${file.path}`)
    return userFile.exists(file.path)
      .catch(() => userFile.create(file.path, ''))
      .then(() => this.ipfs.hashMatch(file.path, file.IPFSHash))
      .then(isInStore => {
        if (!isInStore) return this.ipfs.download(file.IPFSHash, file.path,
          this.progressHandler)
        logger.info(`[SYNC:done] ${file.path}: the file is up to date`)
      })
  }

  reqJoin(authAPIObject) {

    let home = null

    return userFile.getHostedChunks()
      .then(hashes => ({auth: authAPIObject, hosting: hashes}))
      .then(data => this.request('JOIN', data))
      .tap(() => logger.info('[JOIN] Logged in'))
      .then(params => {
        home = params.home
        return this.recvFADD({parameters: {files: [params.home]}})
      })
      .then(() => this.addFilesUnknownByServ(home))
      .tap(() => logger.info('[JOIN] home synchronized'))
  }

  recvFADD(req, print=true) {
    if (print) logger.debug(`[RECV:FADD] ${logger.toJson(req.parameters)}`)

    let files = req.parameters.files
    if (!Array.isArray(files))
      files = Object.keys(files).map(key => files[key])

    return Promise.map(files, (file) => {
      this.fsWatcher.ignore(file.path)
      return (file.isDir ? this.syncDir(file) : this.syncFile(file))
        .delay(500)
        .then(() => this.fsWatcher.unignore(file.path))
    })
  }

  recvFUPT(req) {
    logger.debug(`[RECV:FUPT] ${logger.toJson(req)}`)
    return this.recvFADD(req, false)
  }

  recvFDEL(req) {
    logger.debug(`[RECV:FDEL] ${logger.toJson(req)}`)
    return Promise
      .map(req.parameters.files, file => {
        this.fsWatcher.ignore(file)
        return userFile.del(file)
      })
      .delay(500)
      .each(file => {
        this.fsWatcher.unignore(file.path)
        logger.debug(`removed file ${file.path}`)
      })
  }

  recvFMOV(req) {
    logger.debug(`[RECV:FMOV] ${logger.toJson(req)}`)
    this.fsWatcher.ignore(req.parameters.src)
    this.fsWatcher.ignore(req.parameters.dest)
    return userFile.move(req.parameters.src, req.parameters.dest)
      .delay(500)
      .tap(file => {
        logger.debug(`moved file ${file.src} to ${file.dst}`)
        this.fsWatcher.unignore(file.src)
        this.fsWatcher.unignore(file.dst)
      })
  }

  recvFSTR(req) {
    logger.debug(`[RECV:FSTR] ${logger.toJson(req)}`)
    const hash = req.parameters.hash
    if (hash.length === 0) return Promise.resolve() // QUICKFIX
    if (req.parameters.keep)
      return this.ipfs.download(hash)
    else
      return this.ipfs.rm(hash).then(() => userFile.chunkDel(hash))
  }

  getFsEvent(ev) {
    let handler = this[`send${ev.type}`]
    if (handler == null) return false

    handler.call(this, ev.path).catch(logger.error)
    return true
  }

  sendFADD(filePath) {
    const hashFunc = this.ipfs.getFileHash.bind(this.ipfs)
    return userFile.generateTree(hashFunc, filePath, false)
      .then(file => this.request('FADD', {files: [file]}))
      .catch(err => logger.error('FADD: ' + err))
  }

  sendFUPT(filePath) {
    const hashFunc = this.ipfs.getFileHash.bind(this.ipfs)
    return userFile.generateTree(hashFunc, filePath, false)
      .then(file => this.request('FUPT', {files: [file]}))
      .catch(err => logger.error('FUPT: ' + err))
  }

  sendFDEL(filePath) {
    return this.request('FDEL', {files: [filePath]})
      .catch(err => logger.error('FDEL: ' + err))
  }

  sendFMOV(src, dst) {
    return this.request('FMOV', {src, dst})
      .catch(err => logger.error('FMOV: ' + err))
  }

  setProgressHandler(progressHandler) {
    this.progressHandler = progressHandler
  }

  asciiProgressBar(percent, file) {
    if (!this.progressBars.has(file.path)) {
      const fmt = `[DL] ${file.path} [:bar] :percent :elapseds :etas`
      this.progressBars.set(file.path, progressBar.newBar(fmt, {
        complete: '=',
        incomplete: ' ',
        total: 100, // TODO
        width: 60,
      }))
    }
    const bar = this.progressBars.get(file.path)
    bar.update(Math.floor(percent) / 100)
    if (bar.completed) {
      this.progressBars.delete(file.path)
    }
  }
}
