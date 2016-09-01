import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import userFile from './user-file.js'
import logger from '../../lib/log'
import Watcher from './watcher'
import {Command, Response} from '../../lib/protocol-objects'
import store from './store.js'
import * as ipfs from './ipfs'
import settings from './settings'

const MAX_RECO_TIME = 4
const authTypes = {
  'facebook': 'fb',
  'google': 'gg'
}

export default class Client {

  constructor() {
    this.recoTime = 1
    this.responseHandlers = {} // custom server response handlers
    this.ipfs = ipfs.createNode()
    this.fsWatcher = new Watcher(settings.getStoreDir())
  }

  auth(type, opener) {
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

  developer() {
    logger.info('[AUTH] login as developer')
    return this.reqJoin('gg', 'developer')
  }

  login() {
    throw new Error('[AUTH] StoreIt auth not implemented yet') // TODO
  }

  connect() {
    const {SERVER_ADDR, SERVER_PORT} = process.env
    this.sock = new WebSocket(`ws://${SERVER_ADDR}:${SERVER_PORT}`)
    this.sock = Promise.promisifyAll(this.sock)
    logger.info('[SOCK] attempting connection')

    this.sock.on('error', () => logger.error('[SOCK] socket error occured'))
    this.sock.on('message', data => this.manageResponse(JSON.parse(data)))

    return new Promise(resolve => {
      this.sock.on('open', resolve)
      this.sock.on('close', () => resolve(this.reconnect()))
    })
      .then(() => this.recoTime = 1)
      .tap(() => logger.info('[SOCK] connection established'))
  }

  reconnect() {
    logger.error(`[SOCK] attempting to reconnect in ${this.recoTime} seconds`)
    let done = Promise.delay(this.recoTime * 1000).then(() => this.connect())
    if (this.recoTime < MAX_RECO_TIME) ++this.recoTime
    return done
  }

  watch() {
    this.fsWatcher.setEventHandler((ev) => this.handleFsEvent(ev))
  }

  unwatch() {
    this.fsWatcher.setEventHandler(null)
  }

  manageResponse(res) {
    let handler = this.responseHandlers[res.commandUid]
    if (handler != null) delete this.responseHandlers[res.commandUid]
    else handler = this[`recv${res.command}`] // set to default handler

    if (handler != null) handler.call(this, res)
    else logger.error(`[RESPONSE:orphan] ${logger.toJson(res)}`)
  }

  send(data, type='') {
    logger.debug(`[SEND:${type}] ${logger.toJson(data)}`)
    return this.sock.sendAsync(JSON.stringify(data))
  }

  response(uid, msg='', code=0) {
    return this.send(new Response(code, msg, uid), 'response')
  }

  success(uid, msg='') {
    return this.response(uid, msg, 0)
  }

  error(uid, msg='error', code=1) {
    return this.response(uid, msg, code)
  }

  waitResponse(req) {
    let msg
    return new Promise((resolve, reject) => {
      this.responseHandlers[req.uid] = res => {
        msg = `[RESP:${res.code === 0 ? 'ok' : 'err'}] ${logger.toJson(res)}`
        res.code === 0 ? resolve(res) : reject(new Error(msg))
      }
    }).tap(() => logger.debug(msg))
  }

  request(req, params) {
    let data = new Command(req, params)
    return this.send(data, 'request')
      .then(() => this.waitResponse(data))
      .then(res => res.parameters)
  }

  reqJoin(authType, accessToken) {
    return store.getHostedChunks()
      .then(hashes => ({authType, accessToken, hosting: hashes}))
      .then(data => this.request('JOIN', data))
      .tap(() => logger.info('[JOIN] Logged in'))
      .then(params => this.recvFADD({parameters: {files: [params.home]}}))
      .tap(() => logger.info('[JOIN] home synchronized'))
      .tap(() => this.watch())
      .catch(err => logger.error(err))
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
            if (!isInStore) return this.ipfs.download(file.path, file.IPFSHash)
            logger.info(`[SYNC:done] ${file.path}: the file is up to date`)
          })
          .catch(logger.error)
          .finally(() => this.fsWatcher.unignore(file.path))
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
    return store.FSTR(this.ipfs, req.parameters.hash, req.parameters.keep)
      .then(() => this.success(req.uid))
      .catch(err => logger.error('FSTR: ' + err))
  }

  sendFADD(filePath) {
    return userFile.generateTree(filePath)
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

  handleFsEvent(ev) {
    let handler = this[`send${ev.type}`]
    if (handler) {
      handler.call(this, ev.path).catch(logger.error)
      return true
    }
    return false
  }

  reloadSettings() {
    // TODO
    settings.reload()
  }
}
