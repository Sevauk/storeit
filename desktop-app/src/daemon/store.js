// code for hosting other people files via ipfs

import * as fs from 'fs'
import * as path from 'path'
import logger from '../../lib/log.js'

let home = process.env[process.platform === 'win32' ? 'USERPROFILE' : 'HOME']
if (!home) {
  home = './'
}

const ipfsStore = home + path.sep + '.storeit/'

try {
  fs.mkdirSync(ipfsStore)
}
catch (e) {
}

const getHostedChunks = () => new Promise((resolve, reject) => {
  fs.readdir(ipfsStore, (err, files) => {
    if (err)
      return reject(err)
    return resolve(files)
  })
})

const FSTR = (ipfs, hash, keep) => {

  return new Promise((resolve) => {

    if (!keep) {
      if (ipfs.rm != null)
        ipfs.rm(hash) // QUICK FIX, FIXME
      return resolve()
    }

    if (hash.substr(0, 2) !== 'Qm')
      throw new Error('bad IPFS Hash ' + hash)

    logger.debug(ipfsStore + hash)
    return ipfs.get(hash, ipfsStore + hash)
      .then((data) => fs.writeFile(ipfsStore + hash, data)) // TODO: ipfs add directly instead
  })
}

export default {
  FSTR,
  ipfsStore,
  getHostedChunks
}
