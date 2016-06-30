import * as fs from 'fs'
import * as path from 'path'
import * as api from './protocol-objects.js'
import {logger} from './log.js'

let usersDir = './storeit-users/'

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

  const userHomePath = `${usersDir}/${email}`

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

  setTree(destPath, action) {

    if (this.home === undefined) {
      logger.error('home has not loaded')
    }

    const pathToFile = destPath.split(path.sep)
    const stepInto = (path, tree) => {

      if (pathToFile.length === 1) {
        return action(tree, pathToFile[0])
      }

      const name = pathToFile.shift()
      return stepInto(pathToFile, tree.files[name])
    }
    pathToFile.shift()
    return stepInto(pathToFile, this.home)
  }

  setTrees(trees, action) {
    for (const treeIncoming of trees) {
      this.setTree(treeIncoming.path, (treeParent, name) =>
        action(treeParent, treeIncoming, name))
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
    const takenTree = this.setTree(src, (treeParent, name) => {
      const tree = treeParent.files[name]
      delete treeParent.files[name]
      return tree
    })

    this.setTree(dest, (treeParent, name) => {
      treeParent.files[name] = takenTree

      const rec = (tree, name, currentPath) => {

        const sep = currentPath === '/' ? '' : path.sep
        tree.path = currentPath + sep + name

        if (!tree.files) {
          return
        }

        for (const file of Object.keys(tree.files)) {
          rec(tree.files[file], file, tree.path)
        }
      }

      rec(takenTree, name, treeParent.path)
    })

  }

  delTree(paths) {
    for (const p of paths) {
      this.setTree(p, (tree, name) => delete tree.files[name])
    }
  }

  loadHome(handlerFn) {
    readHome(this.email, (err, obj) => {
      this.home = obj
      handlerFn(err, obj)
    })
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
    handlerFn(err, user)
  })

  logger.info(`${user.email} has connected. ${getStat()}`)
}
