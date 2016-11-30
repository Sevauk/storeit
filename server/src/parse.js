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

    let usrPromised = null

    const unlock = usr => {
      store.processHash(socket, arg)
      sendWelcome(socket, usr, command.uid, {email, profilePic}, handlerFn)
    }

    user.connectUser(email, socket)
      .then(usr => {
        usrPromised = usr
        unlock(usr)
      })
      .catch(err => {
        if (err && err.code === 'ENOENT') {
          logger.info('new user ' + email)
          user.createUser(email, (err) => {
            if (err) {
              return handlerFn(protoObjs.ApiError.SERVERERROR)
            }
            user.connectUser(email, socket, (err, usrPromised) => {
              if (err) {
                return handlerFn(protoObjs.ApiError.SERVERERROR)
              }
              unlock(usrPromised)
            })
          })
        }
        else {
          logger.error(err)
        }
      })
  })
}

const recast = (command, client) => {

  const uid = command.uid
  const usr = client.getUser()
  command.uid = ++usr.commandUid

  logger.debug(`recasting with ${user.getStat()} command ${command.command} to ${Object.keys(usr.sockets).length}`)
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

  if (command.commandUid !== undefined) {
    return logger.debug('client sent a response without uid (' + JSON.stringify(command) + ')')
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

  const usr = client.getUser(client)
  logger.debug(`User ${usr ? usr.email : 'unknown'} sent ${command.command}`)

  // TODO: catch the goddam exception
  const err = hmap[command.command](command, command.parameters, client, (err) => {
    if (err) client.answerFailure(command.uid, err)
  })
  if (err) client.answerFailure(command.uid, err)
}
