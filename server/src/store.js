import * as tool from './tool.js'
import * as store from './store.js'

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

  while (instances++ < targetCount) {
    
  }
}
