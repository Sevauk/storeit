import ipfs from 'ipfs-api'
import {logger} from '../lib/log'
import usrFile from './user-file.js'

export default class IPFSNode {
  constructor() {
    logger.info('[IPFS] connecting to IPFS...')
    this.connect()
    logger.info('[IPFS] connected')
  }

  connect() {
    this.node = ipfs(`/ip4/127.0.0.1/tcp/${process.env.IPFS_PORT}`)
    return Promise.resolve(true)
  }

  addRelative(filePath) {
    return this.add(usrFile.fullPathStoreDir + filePath)
  }
  add(filePath) {
    return this.node.add(filePath)
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
        return this.connect()
          .then(() => this.get(hash))
      })
  }
}
