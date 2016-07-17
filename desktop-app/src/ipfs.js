import ipfs from 'ipfs-api'

import {logger} from '../lib/log'
import usrFile from './user-file.js'

export default class IPFSnode {
  constructor() {
    logger.info('connecting to IPFS...')
    this.connect()
  }

  connect(cb) {
    this.node = ipfs(`/ip4/127.0.0.1/tcp/${process.env.IPFS_PORT}`)
    if (cb) cb()
  }

  add(filePath) {
    return this.node.add(usrFile.fullPath(filePath))
  }

  get(hash) {
    let data = []

    return this.node.cat(hash)
      .then((res) => new Promise((resolve) => {
        res.on('end', () => resolve(Buffer.concat(data)))
        res.on('data', (chunk) => data.push(chunk))
      }))
      .catch((err) => {
        logger.error(err)
        this.connect(() => this.get(hash))
      })
  }
}
