// code for hosting other people files via ipfs

import * as fs from 'fs'
import * as ipfs from './ipfs.js'

// TODO: make this windows compatible
export const ipfsStore = '~/.storeit'

try {
  fs.mkdirSync(ipfsStore)
}
catch (e) {
}

const FSTR = (hash, keep) => {

  return new Promise((resolve, reject) => {

    if (!keep) {
      ipfs.rm(hash)
      return resolve()
    }

    ipfs.get(hash, '~/.storeit/' + hash, (err) => {
      if (err) {
        return reject(err)
      }

      return resolve()
    })
  })
}

export default {
  FSTR
}
