import * as tool from './tool.js'
import * as store from './store.js'
import * as user from './user.js'
import * as api from './common/protocol-objects.js'
import {logger} from './common/log.js'

export const storeTable = new tool.TwoHashMap()

export const registerHashesForUser = (socket, hashes) => {
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
  let instances = store.storeTable.count(hash)

  if (instances >= targetCount)
    return

  const amountNeeded = targetCount - instances
  const users = store.storeTable.selectA(hash, amountNeeded)

  if (users.size < amountNeeded)
    logger.warn('insufficient amount of users needed to have good redundancy')

  for (const usr of users) {
    user.getSocketFromUid(usr).sendObj(new api.Command('FSTR', {hash, 'keep': true}), (err) => {
      if (err) {
        return logger.debug('user did not FSTR as asked (TODO: punish him and try with someone else)')
      }
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
