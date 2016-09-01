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
    this.connect()
  }

  connect() {
    this.sock = new WebSocket(`ws://${this.addr}:${this.port}`)
    this.sock.onopen = () => this.recoTime = 1
    this.sock.onmessage = (ev) => this.manageResponse(JSON.parse(ev.data))
    this.sock.onerror = () => this.reconnect()
  }

  reconnect() {
    console.error(`attempting to reconnect in ${this.recoTime} seconds`)
    setTimeout(() => this.connect(), this.recoTime * 1000)
    if (this.recoTime < MAX_RECO_TIME) ++this.recoTime
  }

  request(cmd, params, noHandler=false) {
    let req = new Request(cmd, params)
    this.sock.send(JSON.stringify(req))
    if (noHandler) return Promise.resolve()
    return new Promise((resolve) => this.handlers[req.uid] = resolve)
  }

  manageResponse(res) {
    console.log('received: ', JSON.stringify(res))
    let handler = this.handlers[res.commandUid]
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
