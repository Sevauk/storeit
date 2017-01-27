import angular from 'angular'

import constants from './constants'
import {Command as Request} from '/lib/protocol-objects'

const MAX_RECO_TIME = 4

class StoreItClientService {
  constructor(STOREIT) {
    'ngInject'

    this.handlers = {}
    this.addr = STOREIT.serverAddr
    this.port = STOREIT.serverPort
    this.recoTime = 1
    this.isReady = false
    this.connect()
  }

  connect() {
    this.sock = new WebSocket(`ws://${this.addr}:${this.port}`)
    this.onReady = new Promise(resolve => this.sock.onopen = () => {
      this.isReady = true
      this.recoTime = 1
      resolve()
    })
    this.sock.onmessage = (ev) => {
      const msg = JSON.parse(ev.data)
      console.log('received: ', JSON.stringify(msg))
      if (msg.command === 'RESP')
        this.manageResponse(msg)
      else
        this.manageMessage(msg)
    }
    this.sock.onerror = () => this.reconnect()
  }

  reconnect() {
    console.error(`attempting to reconnect in ${this.recoTime} seconds`)
    setTimeout(() => this.connect(), this.recoTime * 1000)
    if (this.recoTime < MAX_RECO_TIME) ++this.recoTime
  }

  ready() {
    if (this.isReady) return Promise.resolve()
    return this.onReady
  }

  request(cmd, params, noHandler=false) {
    let req = new Request(cmd, params)
    console.log('sending: ', JSON.stringify(req))
    this.ready()
      .then(() => this.sock.send(JSON.stringify(req)))
    if (noHandler) return Promise.resolve()
    return new Promise((resolve) => this.handlers[req.uid] = resolve)
  }

  manageMessage(msg) {
    const handler = this.handlers[msg.command]
    if (handler) {
      handler(msg.parameters)
    }
  }

  manageResponse(res) {
    const handler = this.handlers[res.commandUid]
    if (handler) {
      handler(res.parameters)
      delete this.handlers[res.commandUid]
    }
  }
}

const DEPENDENCIES = [
  constants,
]

export default angular.module('storeit.client', DEPENDENCIES)
  .service('StoreItClient', StoreItClientService)
  .name
