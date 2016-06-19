import * as ws from 'ws'
import {logger} from './log.js'
import * as proto from './parse.js'
import * as user from './user.js'

const PORT = 7641

const wss = ws.Server({port: PORT})

const ClientStatus = {
  LOGGED: 1,
  UNLOGGED: 2
}

let clientUid = 0

class Client {

  constructor(ws) {
    this.ws = ws
    this.uid = clientUid++

    ws.on('message', (mess) => {
      proto.parse(mess, this)
    })

    ws.on('close', (connection, closeReason, description) => {
      user.disconnectSocket(this)
    })
  }

  sendText(txt) {
    this.ws.send(txt)
  }

  sendObj(obj) {
    this.sendText(JSON.stringify(obj))
  }
}

wss.on('connection', (ws) => {
  new Client(ws)
})

logger.info(`listening on ${PORT}`)
