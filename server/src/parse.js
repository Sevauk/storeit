import {logger} from './log.js'
import * as user from './user.js'
import * as protoObjs from './protocol-objects'
import * as auth from './auth.js'

const sendWelcome = (socket, usr, commandUid, handlerFn) => {
  socket.sendObj(new protoObjs.Response(0, 'welcome', commandUid, {
    home: usr.home
  }))
  handlerFn()
}

const join = function(command, arg, socket, handlerFn) {

  // TODO: error checking on JSON
  auth.verifyUserToken(arg.authType, arg.accessToken, (err, email) => {

    if (err) {
      return handlerFn(err)
    }

    user.connectUser(email, socket, (err, usr) => {
      if (err && err.code === "ENOENT") {
        user.createUser(email, (err) => {
          if (err) {
            return handlerFn(protoObjs.Error.SERVERERROR)
          }
          user.connectUser(email, socket, (err, usrAgain) => {
            if (err) {
              return handlerFn(protoObjs.Error.SERVERERROR)
            }
            sendWelcome(socket, usrAgain, command.uid, handlerFn)
          })
        })
      }
      else if (err) {
        return handlerFn(err)
      }
      else {
        sendWelcome(socket, usr, command.uid, handlerFn)
      }
    })
  })
}

const recast = (command, client) => {

  const uid = command.uid
  const usr = client.getUser()
  command.uid = ++usr.commandUid
  for (const sock in usr.sockets) {
    if (parseInt(sock) === client.uid) {
      continue
    }
    usr.sockets[sock].sendObj(command)
  }

  client.answerSuccess(uid)
}

const add = (command, arg, client) => {
  client.getUser().addTree(arg.files)
  logger.info('user tree: ' + client.getUser().home)
  recast(command, client)
}

const upt = (command, arg, client) => {
  client.getUser().uptTree(arg.files)
  recast(command, client)
}

const mov = (command, arg, client) => {
  client.getUser().renameFile(arg.src, arg.dest)
  recast(command, client)
}

const del = (command, arg, client) => {
  client.getUser().delTree(arg.files)
  recast(command, client)
}

export const parse = function(msg, client) {

  const command = JSON.parse(msg)

  const hmap = {
    'JOIN': join,
    'FADD': add,
    'FUPT': upt,
    'FMOV': mov,
    'FDEL': del
  }

  // TODO: catch the goddam exception
  hmap[command.command](command, command.parameters, client, (err) => {
    if (err) {
      logger.debug('sending failure response: ' + err)
      client.answerFailure(command.uid, err)
    }
  })
}
