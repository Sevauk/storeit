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
    this.authSettigns = {}
    const ignored = userFile.storePath(settings.getHostDir())
    this.fsWatcher = new Watcher(settings.getStoreDir(), ignored,
      (ev) => this.getFsEvent(ev))
  }

  start(opts={}) {
    this.authSettigns.type = opts.type || this.authSettigns.type
    this.authSettigns.devId = opts.devId || this.authSettigns.devId || 0
    this.authSettigns.win = opts.win || this.authSettigns.win

    return Promise.all([
      this.fsWatcher.start(),
      this.ipfs.connect(),
      this.connect()
    ])
  }

  stop() {
    return Promise.all([
      this.fsWatcher.stop(),
      this.ipfs.close(),
      this.close()
    ])
  }

  auth() {
    let service
    switch (this.authSettigns.type) {
      case 'facebook':
        service = new FacebookService()
        break
      case 'google':
        service = new GoogleService()
        break
      case 'developer':
        return this.developer()
      default:
        return this.login()
    }

    logger.info(`[AUTH] login with ${this.authSettigns.type} OAuth`)
    return service.oauth(this.authSettigns.win)
      .then(tokens => this.reqJoin(authTypes[this.authSettigns.type], tokens.access_token))
  }

  developer(devId='') {
    logger.info('[AUTH] login as developer')
    return this.reqJoin('gg', `developer${devId}`)
  }

  login() {
    throw new Error('[AUTH] StoreIt auth not implemented yet') // TODO
  }

  connect() {
    return super.connect()
      .then(() => this.auth(this.authSettigns))
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
        if (!isInStore) return this.ipfs.download(file.IPFSHash, file.path)
        logger.info(`[SYNC:done] ${file.path}: the file is up to date`)
      })
  }

  reqJoin(authType, accessToken) {

    let home = null

    return userFile.getHostedChunks()
      .then(hashes => ({authType, accessToken, hosting: hashes}))
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
    return userFile.generateTree(filePath)
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
}
