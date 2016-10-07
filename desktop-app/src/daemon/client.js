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
    super((...args) => WebSocket(...args))

    this.ipfs = new IPFSNode()
    const ignored = userFile.storePath(settings.getHostDir())
    this.fsWatcher = new Watcher(settings.getStoreDir(), ignored,
      (ev) => this.getFsEvent(ev))
  }

  start() {
    return Promise.all([
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

  auth(type, devId, opener) {
    let service
    switch (type) {
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

    logger.info(`[AUTH] login with ${type} OAuth`)
    return service.oauth(opener)
      .then(tokens => this.reqJoin(authTypes[type], tokens.access_token))
  }

  developer(devId='') {
    logger.info('[AUTH] login as developer')
    return this.reqJoin('gg', `developer${devId}`)
  }

  login() {
    throw new Error('[AUTH] StoreIt auth not implemented yet') // TODO
  }

  reloadSettings() {
    // TODO
    settings.reload()
  }

  reqJoin(authType, accessToken) {
    return userFile.getHostedChunks()
      .then(hashes => ({authType, accessToken, hosting: hashes}))
      .then(data => this.request('JOIN', data))
      .tap(() => logger.info('[JOIN] Logged in'))
      .then(params => this.recvFADD({parameters: {files: [params.home]}}))
      .tap(() => logger.info('[JOIN] home synchronized'))
      .tap(() => this.fsWatcher.start())
  }

  recvFADD(req, print=true) {
    const params = req.parameters
    if (print) logger.debug(`[RECV:FADD] ${logger.toJson(params)}`)

    if (!params.files) return Promise.resolve()

    if (!Array.isArray(params.files)) {
      params.files = Object.keys(params.files).map(key => params.files[key])
    }

    return Promise.map(params.files, (file) => {
      this.fsWatcher.ignore(file.path)
      if (file.isDir) {
        return userFile.dirCreate(file.path)
          .tap(() => logger.info(`[DIR-SYNC] ${file.path}`))
          .then(() => this.recvFADD({parameters: {files: file.files}}, false))
          .tap(() => logger.info(`[DIR-SYNC:end] ${file.path} `))
      }
      else {
        logger.info(`[SYNC:start] ${file.path}`)
        return userFile.exists(file.path)
          .catch(() => userFile.create(file.path, ''))
          .then(() => this.ipfs.hashMatch(file.path, file.IPFSHash))
          .then(isInStore => {
            if (!isInStore) return this.ipfs.download(file.IPFSHash, file.path)
            logger.info(`[SYNC:done] ${file.path}: the file is up to date`)
          })
          .catch(logger.error)
          .then(() => this.fsWatcher.unignore(file.path))
      }
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
