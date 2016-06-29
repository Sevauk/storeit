import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import {logger} from '../lib/log'
import {Command} from '../lib/protocol-objects'

let recoTime = 1

export default class Client {

  constructor() {
    this.listeners = {}
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
        this.addResponseListener(cmd.uid, (data) => this.getRemoteTree(data))
      )
  }

  login() {
    throw {msg: 'StoreIt auth not implemented yet'}
  }

  connect() {
    const {SERVER_HOST, SERVER_PORT} = process.env
    this.sock = new WebSocket(`ws://${SERVER_HOST}:${SERVER_PORT}`)

    this.sock.on('open', () => true)
    this.sock.on('close', () => this.reconnect())
    this.sock.on('error', () => logger.error('socket error occured'))
    this.sock.on('message', (data) => this.handleResponse(JSON.parse(data)))
  }

  reconnect() {
    logger.error('attempting to reconnect in ' + recoTime + ' seconds')
    setTimeout(() => this.connect(), recoTime * 1000)

    const MAX = 4
    if (recoTime < MAX) {
      recoTime++
    }
  }


  addResponseListener(uid, listener) {
    logger.debug('attaching handler for command', uid)
    this.listeners[uid] = listener
  }

  handleResponse(res) {
    let handler = this.listeners[res.commandUid]
    if (handler != null) {
      this.listeners[res.commandUid] = null
      return handler(res.params)
    }

    return // TODO
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

  fileAdd(files) {
    return this.send('FADD', {files})
  }

  fileUpdate(files) {
    return this.send('FUPT', {files})
  }

  fileDel(files) {
    return this.send('FDEL', {files})
  }

  fileMove(src, dst) {
    return this.send('FMOV', {src, dst})
  }

  getRemoteTree(files) {
    return files
  }
}
