import * as fs from 'fs'
import * as path from 'path'
import * as api from './common/protocol-objects.js'
import * as tree from './common/tree.js'
import {logger} from './common/log.js'

let usersDir = 'storeit-users' + path.sep

export const setUsersDir = (name) => {
  usersDir = name
}

export const makeBasicHome = () => {

  const readmeHash = 'Qmco5NmRNMit3V2u3whKmMAFaH4tVX4jPnkwZFRdsb4dtT'
  return api.makeFileObj('/', null, {
    'readme.txt': api.makeFileObj('/readme.txt', readmeHash)
  })
}

export const createUser = (email, handlerFn) => {

  const userHomePath = `${usersDir}${path.sep}${email}`

  const basicHome = makeBasicHome()

  fs.writeFile(userHomePath, JSON.stringify(basicHome, null, 2), (err) => handlerFn(err))
}

const readHome = (email, handlerFn) => {
  fs.readFile(usersDir + email, 'utf8', (err, data) => {
    if (err) {
      return handlerFn(err)
    }

    handlerFn(err, JSON.parse(data))
  })
}

export class User {

  constructor(email) {
    this.email = email
    this.sockets = {}
    this.commandUid = 0
  }

  setTrees(trees, action) {
    for (const treeIncoming of trees) {
      const tri = tree.setTree(this.home, treeIncoming.path, (treeParent, name) =>
        action(treeParent, treeIncoming, name))
      if (tri) return tri
    }
  }

  addTree(trees) {
    return this.setTrees(trees, (treeParent, tree, name) => {
      treeParent.files[name] = tree
    })
  }

  uptTree(trees) {
    return this.setTrees(trees, (treeParent, tree, name) => {
      treeParent.files[name] = tree
    })
  }

  renameFile(src, dest) {

    let takenTree = tree.setTree(this.home, src, (treeParent, name) => {
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
        const err = tree.setTree(this.home, p, (tree, name) => delete tree.files[name])
        if (err !== true)
          return err
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
    fs.writeFile(usersDir + this.email, JSON.stringify(this.home, null, 2))
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
  logger.info(`${user.email} has disconnected. ${getStat()}`)
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
