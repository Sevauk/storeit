import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import userFile from './user-file.js'

import StoreitClient from '../../lib/client'
import logger from '../../lib/log'
import Watcher from './watcher'
import IPFSNode from './ipfs'
import settings from './settings'

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
    this.progressHandler = (percent, file) =>
      logger.info(`[DL] <${Math.floor(percent)}%> ${file.path}`)
  }

  start(opts={}) {
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
    logger.info('[STATUS] attempting to gracefully shut down daemon')
    return this.fsWatcher.stop()
      .then(() => this.close())
      .then(() => this.ipfs.close())
      .then(() => logger.info('[STATUS] daemon stopped'))
  }

  auth() {
    let service
    switch (this.authSettings.type) {
      case 'facebook':
        service = new FacebookService()
        break
      case 'google':
        service = new GoogleService()
        break
      case 'st':
        return this.login('john.doe@gmail.com', 'physics') // TODO: use tokens returned by our backend
      case 'developer':
        return this.developer()
      default:
        throw new Error('invalid authentication type')
    }

    logger.info(`[AUTH] login with ${this.authSettings.type} OAuth`)
    return service.oauth(this.authSettings.win)
      .then(tokens => this.reqJoin({type: authTypes[this.authSettings.type], accessToken: tokens.access_token}))
      .catch(e => {
        logger.error(`[AUTH] login failed ${e}`)
        throw new Error(e)
      })
  }

  developer(devId='') {
    logger.info('[AUTH] login as developer')
    return this.reqJoin('gg', `developer${devId}`)
  }

  login(email, password) {
    logger.info(`logining with ${'StoreIt'}`)
    this.request('AUTH', {email, password})
      .then(resp => {
        logger.debug(`got token ${resp.accessToken}`)
        return this.reqJoin({type: 'st', accessToken: resp.accessToken})
      })

  }

  connect() {

    return super.connect()
      .then(() => this.auth(this.authSettings))
      .catch((e) => {
        logger.debug(`connect error: ${logger.toJson(e)}`)
        return this.reconnect()
      })
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
      .map(req.parameters.files, file => userFile.del(file))
      .each(file => logger.debug(`removed file ${file.path}`))
  }

  recvFMOV(req) {
    logger.debug(`[RECV:FMOV] ${logger.toJson(req)}`)
    return userFile.move(req.parameters.src, req.parameters.dest)
      .tap(file => logger.debug(`moved file ${file.src} to ${file.dst}`))
  }

  recvFSTR(req) {
    logger.debug(`[RECV:FSTR] ${logger.toJson(req)}`)
    const hash = req.parameters.hash
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
    return userFile.generateTree(hashFunc, filePath)
      .then(files => this.request('FADD', {files: [files]}))
      .catch(err => logger.error('FADD: ' + err))
  }

  sendFUPT(filePath) {
    const hashFunc = this.ipfs.getFileHash.bind(this.ipfs)
    return userFile.generateTree(hashFunc, filePath)
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
}
