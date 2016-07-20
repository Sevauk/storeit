// code for hosting other people files via ipfs

import * as fs from 'fs'

// TODO: make this windows compatible
export const ipfsStore = '~/.storeit'

try {
  fs.mkdirSync(ipfsStore)
}
catch (e) {
}

const FSTR = (ipfs, hash, keep) => {

  return new Promise((resolve, reject) => {

    if (!keep) {
      ipfs.rm(hash)
      return resolve()
    }

    if (hash.substr(0, 2) !== 'Qm')
      return reject('bad IPFS Hash ' + hash)

    ipfs.get(hash, '~/.storeit/' + hash, (err) => {
      if (err) {
        reject(err)
      }

      resolve()
    })
  })
}

export default {
  FSTR
}
