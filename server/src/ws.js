import * as ws from 'ws'
import cmd from './main.js'
import {logger} from './lib/log.js'
import * as proto from './parse.js'
import * as user from './user.js'
import * as protoObjs from './lib/protocol-objects.js'

const ClientStatus = {
  LOGGED: 1,
  UNLOGGED: 2
}

let clientUid = 0

class Client {

  constructor(ws) {
    this.ws = ws
    this.uid = clientUid++
    this.responseHandlers = []

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

  sendCmd(name, parameters, handlerResponse) {
    const command = new protoObjs.Command(name, parameters)
    this.sendObj(command)
    this.responseHandlers[command.uid] = handlerResponse
  }

  answerSuccess(commandUid, args) {
    this.sendObj(new protoObjs.Response(0, 'success', commandUid, args))
  }

  answerFailure(commandUid, err) {
    logger.debug('sending error to client ' + err.msg)
    this.sendObj(new protoObjs.Response(err.code, err.msg, commandUid, err.trace))
  }
}

export const listen = () => {
  const wss = ws.Server({port: cmd.port, host: cmd.addr})
  logger.info(`listening on ${cmd.port}`)

  wss.on('connection', (ws) => {
    logger.debug('client connects')
    new Client(ws)
  })
}
