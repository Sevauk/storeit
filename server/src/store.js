import * as tool from './tool.js'
import * as user from './user.js'
import * as api from './lib/protocol-objects.js'
import * as tree from './lib/tree.js'
import * as ipfs from './ipfs.js'
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

const keepChunkAlive = (hash) => {
  let instances = storeTable.count(hash)

  if (instances >= targetCount)
    return

  const amountNeeded = targetCount - instances
  const users = storeTable.selectA(hash, amountNeeded)

  if (users.size < amountNeeded)
    logger.warn('insufficient amount of users needed to have good redundancy')

  for (const usr of users) {
    storeTable.add(usr, hash)
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

const keepFileAlive = (multihash) =>
  ipfs.listChunks(multihash)
    .then(list => {
      if (list.length > 1) {
        for (const hash of list) {
          keepChunkAlive(hash)
        }
      }
      else {
        keepChunkAlive(multihash)
        /* TODO: in order to list the chunks of our file, we made an ipfs object get.
         * when the file is small, the command downloads the entire chunk of data. In
         * this case we have to delete it because the server does not host user files.
         * If the file is big, we must keep the object which is the list of hash (links)
         * to the chunks composing the file (but dont forget to delete it when the file
         * is removed by the user) */
      }
    })


export const keepTreeAlive = (treeCurrent) =>
  tree.forEachHash(treeCurrent, (hash) => {
    keepFileAlive(hash)
  })
