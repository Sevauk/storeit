import {logger} from './lib/log.js'
import * as user from './user.js'
import * as protoObjs from './lib/protocol-objects'
import * as authentication from './auth.js'
import * as store from './store.js'

const sendWelcome = (socket, usr, commandUid, usrProfile, handlerFn) => {
  socket.sendObj(new protoObjs.Response(0, 'welcome', commandUid, {
    home: usr.home,
    usrProfile
  }))
}

const join = function(command, arg, socket, handlerFn) {

  // TODO: error checking on JSON
  if (!arg.auth || !arg.auth.type) // TODO: add more cases
    return handlerFn(protoObjs.ApiError.BADREQUEST)

  authentication.doAuthentication(arg.auth, (err, email, profilePic) => {

    if (err) {
      return handlerFn(err)
    }

    user.connectUser(email, socket, (err, usr) => {

      const unlock = (usr) => {
        store.processHash(socket, arg)
        sendWelcome(socket, usr, command.uid, {email, profilePic}, handlerFn)
      }

      if (err && err.code === 'ENOENT') {
        user.createUser(email, (err) => {
          if (err) {
            return handlerFn(protoObjs.ApiError.SERVERERROR)
          }
          user.connectUser(email, socket, (err, usrAgain) => {
            if (err) {
              return handlerFn(protoObjs.ApiError.SERVERERROR)
            }
            unlock(usrAgain)
          })
        })
      }
      else if (err) {
        return handlerFn(err)
      }
      else unlock(usr)
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

const sendErrIfErr = (uid, socket, err) => {
  if (err) {
    socket.answerFailure(uid, err)
  }
}

const add = (command, arg, client) => {
  const err = client.getUser().addTree(arg.files)
  if (err) return err
  recast(command, client)
}

const upt = (command, arg, client) => {
  const err = client.getUser().uptTree(arg.files)
  if (err) return err
  recast(command, client)
}

const mov = (command, arg, client) => {
  const err = client.getUser().renameFile(arg.src, arg.dest)
  if (err) return err
  recast(command, client)
}

const del = (command, arg, client) => {
  const err = client.getUser().delTree(arg.files)
  if (err) return err
  recast(command, client)
}

const auth = (command, arg, client) => {
  console.log('authenticating user with ' + arg.email + ' ' + arg.password)
  client.answerSuccess(command.uid, {accessToken: 'abcdefg12345'})
}

const resp = (command, arg, client) => {

  if (!command.commandUid) {
    return logger.debug('client sent invalid response')
  }

  const uid = command.commandUid
  logger.debug(client.responseHandlers)
  if (client.responseHandlers && uid in client.responseHandlers && client.responseHandlers[uid]) {
    client.responseHandlers[uid](command.code, command.text)
    delete client.responseHandlers[uid]
  }
}

export const parse = function(msg, client) {

  const command = JSON.parse(msg)

  const hmap = {
    'JOIN': join,
    'FADD': add,
    'FUPT': upt,
    'FMOV': mov,
    'FDEL': del,
    'RESP': resp,
    'AUTH': auth,
  }

  if (command.command !== 'JOIN' && command.command !== 'AUTH' && !client.getUser())
    return client.answerFailure(command.uid, protoObjs.ApiError.BADREQUEST)

  if (!(command.command in hmap)) {
    return client.answerFailure(command.uid, protoObjs.ApiError.UNKNOWNREQUEST)
  }

  logger.debug(`Command is ${JSON.stringify(command, null, 2)}`)

  // TODO: catch the goddam exception
  const err = hmap[command.command](command, command.parameters, client, (err) => {
    if (err) client.answerFailure(command.uid, err)
  })
  if (err) client.answerFailure(command.uid, err)
}
