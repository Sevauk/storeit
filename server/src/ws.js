import * as ws from 'ws'
import {logger} from './common/log.js'
import * as proto from './parse.js'
import * as user from './user.js'
import * as protoObjs from './common/protocol-objects.js'

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

  getUser() {
    return user.sockets[this.uid]
  }

  sendText(txt) {
    this.ws.send(txt)
  }

  sendObj(obj) {
    this.sendText(JSON.stringify(obj))
  }

  answerSuccess(commandUid) {
    this.sendObj(new protoObjs.Response(0, 'success', commandUid))
  }

  answerFailure(commandUid, err) {
    logger.debug('sending error to client ' + err.msg)
    this.sendObj(new protoObjs.Response(err.code, err.msg, commandUid, err.trace))
  }
}

wss.on('connection', (ws) => {
  logger.debug('client connects')
  new Client(ws)
})

logger.info(`listening on ${PORT}`)
