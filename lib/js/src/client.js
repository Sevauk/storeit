/*
  eslint-env node, browser, es6
*/

import {Command, Response} from './protocol-objects'
import log from './log'

const MAX_RECO_TIME = 4
export default class StoreitClient {
  constructor(socketFactory) {
    if (!socketFactory && window != null) {
      socketFactory = (...args) => new window.WebSocket(...args)
    }
    this.socketFactory = socketFactory
    this.responseHandlers = {}
    this.recoTime = 1
  }

  connect() {
    const {SERVER_ADDR, SERVER_PORT} = process.env
    const addr = `ws://${SERVER_ADDR}:${SERVER_PORT}`
    this.sock = this.socketFactory(addr)
    this.sock = Promise.promisifyAll(this.sock)
    log.info(`[SOCK] attempting connection at ${addr}`)

    this.sock.onerror = () => log.error('[SOCK] socket error occured')
    this.sock.onmessage = msg => this.recvMessage(JSON.parse(msg.data))

    return new Promise(resolve => {
      this.sock.onopen = resolve
      this.sock.onclose = () => resolve(this.reconnect())
    })
      .then(() => this.recoTime = 1)
      .tap(() => log.info('[SOCK] connection established'))
  }

  reconnect() {
    log.error(`[SOCK] attempting to reconnect in ${this.recoTime} seconds`)
    let done = Promise.delay(this.recoTime * 1000).then(() => this.connect())
    if (this.recoTime < MAX_RECO_TIME) ++this.recoTime
    return done
  }

  close() {
    this.sock.close()
  }

  recvMessage(msg) {
    let handler = this.responseHandlers[msg.commandUid]

    // message is a server response
    if (handler != null) {
      delete this.responseHandlers[msg.commandUid]
      return handler.call(this, msg)
    }

    // message is a server request
    this[`recv${msg.command}`](msg)
      .then(() => this.success(msg.uid))
      .catch((err) => {
        log.error(`${msg.command}: ${err}`)
        return this.error(msg.uid)
      })
  }

  sendMessage(data, type='') {
    log.debug(`[SEND:${type}] ${log.toJson(data)}`)
    return this.sock.sendAsync(JSON.stringify(data))
  }

  response(uid, msg='', code=0) {
    return this.sendMessage(new Response(code, msg, uid), 'response')
  }

  success(uid, msg='') {
    return this.response(uid, msg, 0)
  }

  error(uid, msg='error', code=1) {
    return this.response(uid, msg, code)
  }

  request(cmd, params) {
    let req = new Command(cmd, params)
    return this.sendMessage(req, 'request')
      .then(() => this.waitResponse(req))
      .then(res => res.parameters)
  }

  waitResponse(req) {
    let msg
    return new Promise((resolve, reject) => {
      this.responseHandlers[req.uid] = res => {
        msg = `[RESP:${res.code === 0 ? 'ok' : 'err'}] ${log.toJson(res)}`
        res.code === 0 ? resolve(res) : reject(new Error(msg))
      }
    }).tap(() => log.debug(msg))
  }
}
