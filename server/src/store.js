import * as tool from './tool.js'

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
