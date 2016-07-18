import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import userFile from './user-file'
import {logger} from '../lib/log'
import Watcher from './watcher'
import IPFSnode from './ipfs'
import {Command, FileObj} from '../lib/protocol-objects'

const MAX_RECO_TIME = 4

export default class Client {

  constructor() {
    this.recoTime = 1
    this.responseHandlers = {} // custom server response handlers
    this.ipfs = new IPFSnode()
    this.fsWatcher = new Watcher(userFile.getStoreDir())
    this.fsWatcher.setEventHandler((ev) => this.handleFsEvent(ev))
    this.connect()
  }

  auth(type) {
    let service
    switch (type) {
    case 'facebook':
      service = new FacebookService()
      type = 'fb'
      break
    case 'google':
      service = new GoogleService()
      type = 'gg'
      break
    default:
      return this.login() // TODO
    }

    return service.oauth()
      .then((tokens) => this.join(type, tokens.access_token))
      .then((cmd) =>
        this.addResponseHandler(cmd.uid, (data) => this.getRemoteTree(data))
      )
  }

  login() {
    throw {msg: 'StoreIt auth not implemented yet'}
  }

  connect() {
    const {SERVER_HOST, SERVER_PORT} = process.env
    this.sock = new WebSocket(`ws://${SERVER_HOST}:${SERVER_PORT}`)

    this.sock.on('open', () => this.recoTime = 1)
    this.sock.on('close', () => this.reconnect())
    this.sock.on('error', () => logger.error('socket error occured'))
    this.sock.on('message', (data) => this.handleResponse(JSON.parse(data)))
  }

  reconnect() {
    logger.error(`attempting to reconnect in ${this.recoTime} seconds`)
    setTimeout(() => this.connect(), this.recoTime * 1000)

    if (this.recoTime < MAX_RECO_TIME) {
      ++this.recoTime
    }
  }

  addResponseHandler(uid, listener) {
    logger.debug('attaching response handler for command', uid)
    this.responseHandlers[uid] = listener
  }

  handleResponse(res) {
    let handler = this.responseHandlers[res.commandUid]
    if (handler != null) {
      this.responseHandlers[res.commandUid] = null
    }
    else {
      handler = this[`recv${res.command}`] // set to default handler
    }

    if (handler == null) {
      logger.error(`received unhandled response: ${JSON.stringify(res)}`)
      return null
    }
    else {
      return handler.call(this, res.parameters)
    }
  }

  send(cmd, params) {
    logger.info(`sending command ${cmd}`)
    let data = new Command(cmd, params)

    return new Promise((resolve, reject) =>
      this.sock.send(JSON.stringify(data), (err) =>
        !err ? resolve(data) : reject(err)
      )
    )
  }

  join(authType, accessToken) {
    return this.send('JOIN', {authType, accessToken})
  }

  recvFADD(params, log=true) {
    if (log) logger.info(`received FADD => ${JSON.stringify(params)}`)

    if (!Array.isArray(params.files))
      params.files = Object.keys(params.files).map((key) => params.files[key])

    let status = []
    let res
    for (let file of params.files) {
      if (file.isDir) {
        res = userFile.dirCreate(file.path)
          .then(() => this.recvFADD({files: file.files}, false))
      }
      else {
        logger.info(`downloading file ${file.path} from ipfs`)
        res = this.ipfs.get(file.IPFSHash)
          .then((buf) => userFile.create(file.path, buf))
          .then(() => this.ipfs.add(file.path))
      }
      status.push(res)
    }
    return Promise.all(status)
  }

  recvFUPT(params) {
    logger.info(`received FUPT => ${JSON.stringify(params)}`)
    return this.recvFADD(params, false)
  }

  recvFDEL(params) {
    logger.info(`received FDEL => ${JSON.stringify(params)}`)
    let status = []
    for (let file of params.files) {
      status.push(userFile.del(file))
    }
    return Promise.all(status)
      .then((files) =>
        files.forEach((file) => logger.info(`removed file ${file.path}`))
      )
  }

  recvFMOV(params) {
    logger.info(`received FMOV => ${JSON.stringify(params)}`)
    return userFile.move(params.src, params.dest)
      .then((file) => logger.info(`moved file ${file.src} to ${file.dst}`))
  }

  sendFADD(files) {
    // TODO: IPFS add here
    // then: get IPFSHash
    return this.send('FADD', {files})
  }

  sendFUPT(files) {
    return this.send('FUPT', {files})
  }

  sendFDEL(files) {
    return this.send('FDEL', {files})
  }

  sendFMOV(src, dst) {
    return this.send('FMOV', {src, dst})
  }

  handleFsEvent(ev) {
    let handler = this[`send${ev.type}`]
    if (handler) {
      let file = new FileObj() // TODO
      return handler.call(this, file)

      // TODO: manage FMOV
    }
    else logger.warn(`[FileWatcher] unhandled event ${ev}`)
  }

  getRemoteTree(files) {
    return files
  }
}
