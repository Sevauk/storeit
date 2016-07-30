import * as tool from './tool.js'
import * as store from './store.js'
import * as user from './user.js'
import * as api from './lib/protocol-objects.js'
import * as tree from './lib/tree.js'
import {logger} from './lib/log.js'

export const storeTable = new tool.TwoHashMap()

export const registerHashesForUser = (socket, hashes) => {
  storeTable.add(socket.uid, '')
  if (hashes !== undefined) {
    for (const hash of hashes) {
      storeTable.add(socket.uid, hash)
    }
  }
}

export const processHash = (socket, arg) => {
  registerHashesForUser(socket, arg.hashes)
}

const targetCount = 5

export const keepChunkAlive = (hash) => {
  let instances = storeTable.count(hash)

  if (instances >= targetCount)
    return

  const amountNeeded = targetCount - instances
  const users = storeTable.selectA(hash, amountNeeded)

  logger.debug('--->' + JSON.stringify(storeTable.map1))

  if (users.size < amountNeeded)
    logger.warn('insufficient amount of users needed to have good redundancy')

  for (const usr of users) {
    storeTable.add(usr, hash)
    logger.debug('ADD' + JSON.stringify(storeTable.map1))
    user.getSocketFromUid(usr).sendObj(new api.Command('FSTR', {hash, 'keep': true}), (err) => {
      if (err) {
        return logger.debug('user did not FSTR as asked (TODO: punish him and try with someone else)')
      }
      storeTable.add(usr, hash) // TODO: why is it not running this line ?
      logger.debug('user did download the chunk')
    })
  }
}

export const removeSocket = (socket) => {

  const offlineChunks = storeTable.get(socket.uid)

  storeTable.remove(socket.uid)

  if (!offlineChunks)
    return

  for (const chunk of offlineChunks) {
    keepChunkAlive(chunk)
  }
}


export const keepTreeAlive = (treeCurrent) => {
  tree.forEachHash(treeCurrent, (hash) => {
    store.keepChunkAlive(hash)
  })
}
