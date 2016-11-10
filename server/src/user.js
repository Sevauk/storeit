import * as fs from 'fs'
import * as path from 'path'
import * as api from './lib/protocol-objects.js'
import * as tree from './lib/tree.js'
import * as store from './store.js'
import {logger} from './lib/log.js'
import cmd from './main.js'

export const makeBasicHome = () => {

  const readmeHash = 'Qmco5NmRNMit3V2u3whKmMAFaH4tVX4jPnkwZFRdsb4dtT'
  return new api.FileObj('/', null, {
    'readme.txt': new api.FileObj('/readme.txt', readmeHash)
  })
}

export const createUser = (email, handlerFn) => {

  const userHomePath = `${cmd.usrdir}${email}`

  const basicHome = makeBasicHome()

  fs.writeFile(userHomePath, JSON.stringify(basicHome, null, 2), (err) => handlerFn(err))
}

const readHome = (email, handlerFn) => {
  fs.readFile(cmd.usrdir + email, 'utf8', (err, data) => {

    if (err) {
      return handlerFn(err)
    }

    try {
      handlerFn(err, JSON.parse(data))
    }
    catch (err) {
      logger.error(`user file for ${email} seems corrupt !`)
      handlerFn(err)
    }
  })
}

export class User {

  constructor(email) {
    this.email = email
    this.sockets = {}
    this.commandUid = 0
  }

  setTrees(trees, action) {

    if (typeof trees[Symbol.iterator] !== 'function') {
      return api.errWithStack(api.ApiError.BADREQUEST)
    }

    for (const treeIncoming of trees) {
      const tri = tree.setTree(this.home, treeIncoming.path, (treeParent, name) => {

        if (!treeIncoming) {
          return api.errWithStack(api.ApiError.BADPARAMETERS)
        }
        return action(treeParent, treeIncoming, name)
      })
      if (tri) return tri
    }
  }

  addTree(trees) {
    return this.setTrees(trees, (treeParent, treeCurrent, name) => {

      if (!treeParent.files) {
        treeParent.files = {}
      }

      treeParent.files[name] = treeCurrent

      store.keepTreeAlive(treeCurrent)
    })
  }

  uptTree(trees) {
    return this.setTrees(trees, (treeParent, treeCurrent, name) => {

      if (!treeParent.files) {
        logger.debug('there is no ' + name + ' in ' + tree.path)
        return api.errWithStack(api.ApiError.BADTREE)
      }

      treeParent.files[name] = treeCurrent

      store.keepTreeAlive(treeCurrent)
    })
  }

  renameFile(src, dest) {

    let takenTree = tree.setTree(this.home, src, (treeParent, name) => {
	if (!treeParent.files)
		return
      const tree = treeParent.files[name]
      delete treeParent.files[name]
      return tree
    })

    if (!takenTree) {
      return api.errWithStack(api.ApiError.BADPARAMETERS)
    }

    if (takenTree.code) {
      return takenTree
    }

    return tree.setTree(this.home, dest, (treeParent, name) => {

      treeParent.files[name] = takenTree

      takenTree.path = dest

      const rec = (tree, name, currentPath) => {

        const sep = currentPath === '/' ? '' : path.sep
        tree.path = currentPath + sep + name

        if (!tree.files)
          return

        for (const file of Object.keys(tree.files)) {
          const err = rec(tree.files[file], file, tree.path)
          if (err) return err
        }
      }

      return rec(takenTree, name, treeParent.path)

    })

  }

  delTree(paths) {
    for (const p of paths) {
      if (typeof p !== 'string') {
        return api.errWithStack(api.ApiError.BADREQUEST)
      }
      else {
        const err = tree.setTree(this.home, p, (treeCurrent, name) => {
          if (!treeCurrent.files) {
            return api.errWithStack(api.ApiError.ENOENT)
          }

          tree.forEachHash(tree, (hash) => {
            // TODO: implement a way to remove hash if it is not needed by anyone anymore
            // use probably a hashmap of all the hashes as keys and clients that need them as value
          })
          return delete treeCurrent.files[name]
        })
        if (err !== true) {
          return err
        }
      }
    }
  }

  loadHome(handlerFn) {
    readHome(this.email, (err, obj) => {
      this.home = obj
      handlerFn(err, obj)
    })
  }

  flushHome() {
    fs.writeFile(cmd.usrdir + this.email, JSON.stringify(this.home, null, 2))
  }
}

export const users = {}
export const sockets = {}

export const getUserCount = () => {
  return Object.keys(users).length
}

export const getConnectionCount = () => {
  return Object.keys(sockets).length
}

const getStat = () => {
  return `${getUserCount()} users ${getConnectionCount()} sockets.`
}

export const disconnectSocket = (client) => {

  const user = sockets[client.uid]

  if (user === undefined) {
    return logger.debug('client is already disconnected')
  }

  delete user.sockets[client.uid]

  user.flushHome()

  if (Object.keys(user.sockets).length === 0) {
    delete users[user.email]
  }

  delete sockets[client.uid]
  store.removeSocket(client)
  logger.info(`${user.email} has disconnected. ${getStat()}`)
}

export const getSocketFromUid = (uid) => {
  const uidStr = uid.toString()
  if (!sockets[uidStr])
    return null
  return sockets[uidStr].sockets[uidStr]
}

export const connectUser = (email, client, handlerFn) => {

  let user = users[email]

  if (user === undefined) {
    user = new User(email)
  }

  sockets[client.uid] = user
  users[email] = user
  user.sockets[client.uid] = client

  user.loadHome((err) => {

    if (err) {
      disconnectSocket(client)
    }
    else {
      logger.info(`${user.email} has connected. ${getStat()}`)
    }
    handlerFn(err, user)
  })
}
