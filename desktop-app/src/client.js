import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import {logger} from '../lib/log'

let recoTime = 1

let uid = 0 // TODO: remove

// TODO: remove
class Command {
  constructor(name, parameters) {
    this.uid = uid++
    this.command = name
    this.parameters = parameters
  }
}

// TODO: remove
class Response { // eslint-disable-line no-unused-vars
  constructor(code, text, uid, parameters) {
    this.code = code,
    this.text = text,
    this.commandUid = uid,
    this.parameters = parameters
  }
}

export default class Client {

  constructor() {
    this.connect()
  }

  auth(type) {
    let service = null
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
    this.sock.on('message', (data) => this.recv(data))
  }

  reconnect() {
    logger.error('attempting to reconnect in ' + recoTime + ' seconds')
    setTimeout(() => this.connect(), recoTime * 1000)

    const MAX = 4
    if (recoTime < MAX) {
      recoTime++
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

  recv(data) {
    return new Promise((resolve) => resolve(JSON.parse(data)))
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
}
