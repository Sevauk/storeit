import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import userFile from './user-file.js'
import logger from '../../lib/log'
import Watcher from './watcher'
import {Command, Response} from '../../lib/protocol-objects'
import store from './store.js'
import tree from './tree.js'
import IPFSnode from './ipfs'
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
    this.ipfs = new IPFSnode()
    this.fsWatcher = new Watcher(settings.getStoreDir())
    this.fsWatcher.setEventHandler((ev) => this.handleFsEvent(ev))
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

    return service.oauth(opener)
      .then(tokens => this.reqJoin(authTypes[type], tokens.access_token))
  }

  developer() {
    return this.reqJoin('gg', 'developer')
  }

  login() {
    throw new Error('StoreIt auth not implemented yet') // TODO
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

  manageResponse(res) {
    let handler = this.responseHandlers[res.commandUid]
    if (handler != null) delete this.responseHandlers[res.commandUid]
    else handler = this[`recv${res.command}`] // set to default handler

    if (handler != null) handler.call(this, res)
    else logger.error(`[PROTO] unhandled response: ${JSON.stringify(res)}`)
  }

  waitResponse(req) {
    let msg = `[PROTO] request ${JSON.stringify(req)} failed`

    return new Promise((resolve, reject) =>
      this.responseHandlers[req.uid] = (res) =>
        res.code === 0 ? resolve(res) : reject(new Error(msg))
    )
      .tap(res => this.recvRESP(res))
      .then(res => res.parameters)
  }

  send(data) {
    logger.info(`[PROTO] sending data ${JSON.stringify(data)}`)
    return this.sock.sendAsync(JSON.stringify(data))
  }

  response(uid, msg='', code=0) {
    return this.send(new Response(code, msg, uid))
  }

  success(uid, msg='') {
    return this.response(uid, msg, 0)
  }

  error(uid, msg='error', code=1) {
    return this.response(uid, msg, code)
  }

  request(req, params) {
    let data = new Command(req, params)
    return this.send(data)
      .then(() => this.waitResponse(data))
  }

  reqJoin(authType, accessToken) {
    return store.getHostedChunks()
      .then(hashes => ({authType, accessToken, hosting: hashes}))
      .then(data => this.request('JOIN', data))
      .then(params => this.recvFADD({files: [params.home]}))
      .then(() => logger.info('[PROTO] home loaded'))
      .catch(err => logger.error(err))
  }

  recvFADD(params, log=true) {
    if (log) logger.info(`[PROTO] received FADD => ${JSON.stringify(params)}`)

    if (!params.files) return Promise.resolve()

    if (!Array.isArray(params.files)) {
      params.files = Object.keys(params.files).map(key => params.files[key])
    }

    return Promise.map(params.files, (file) => {
      this.fsWatcher.ignore(file.path)
      if (file.isDir) {
        return userFile.dirCreate(file.path)
          .then(() => this.recvFADD({files: file.files}, false))
      }
      else {
        const {path, IPFSHash} = file
        return userFile.exists(file.path)
          .catch(() => userFile.create(path, ''))
          .then(() => this.ipfs.isInStore(path, IPFSHash))
          .then((stored) => !stored ? this.ipfs.download(path, IPFSHash) : 0)
          .catch(logger.error)
          .finally(() => this.fsWatcher.unignore(file.path))
      }
    })
  }

  recvRESP(res) {
    const status = res.code === 0 ? 'successful' : 'failure'
    logger.info(`[PROTO] received ${status} ${res.code} response`)
  }

  recvFUPT(params) {
    logger.info(`[PROTO] received FUPT => ${JSON.stringify(params)}`)
    return this.recvFADD(params, false)
  }

  recvFDEL(params) {
    logger.info(`[PROTO] received FDEL => ${JSON.stringify(params)}`)
    return Promise.map(params.files, (file) => userFile.del(file))
      .each((file) => logger.info(`removed file ${file.path}`))
  }

  recvFMOV(params) {
    logger.info(`[PROTO] received FMOV => ${JSON.stringify(params)}`)
    return userFile.move(params.src, params.dest)
      .then(file => logger.info(`moved file ${file.src} to ${file.dst}`))
  }

  recvFSTR(params) {
    logger.info(`[PROTO] received FSTR => ${JSON.stringify(params)}`)
    return store.FSTR(this.ipfs, params.hash, params.keep)
      .then(() => this.success())
      .catch(err => logger.error('FSTR: ' + err))
  }

  sendFADD(filePath) {
    return tree.createTree(filePath, this.ipfs)
      .then(file => this.request('FADD', {files: [file]}))
      .catch(err => logger.error('FADD: ' + err))
  }

  sendFUPT(filePath) {
    return tree.createTree(filePath, this.ipfs)
      .then(file => this.request('FUPT', {files: [file]}))
      .catch(err => logger.error('FUPT: ' + err.text))
  }

  sendFDEL(filePath) {
    return this.request('FDEL', {files: [userFile.storePath(filePath)]})
      .catch(err => logger.error('FDEL: ' + err.text))
  }

  sendFMOV(src, dst) {
    return this.request('FMOV', {src, dst})
      .catch(err => logger.error('FMOV: ' + err.text))
  }

  handleFsEvent(ev) {
    let handler = this[`send${ev.type}`]
    if (handler) {
      handler.call(this, ev.path)
        .catch(logger.debug)

      // TODO: manage FMOV
    }
    else logger.warn(`[FileWatcher] unhandled event ${ev}`)
  }

  reloadSettings() {
    // TODO
    settings.reload()
  }
}
