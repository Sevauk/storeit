import ipfs from 'ipfs-api'
import {logger} from '../../lib/log'
import usrFile from './user-file.js'

const MAX_RECO_TIME = 4

export default class IPFSNode {
  constructor() {
    this.connecting = false
    this.recoTime = 0
    this.connect()
  }

  connect() {

    this.node = ipfs(`/ip4/127.0.0.1/tcp/${process.env.IPFS_PORT}`)

    return this.ready()
      .then(() => {
        logger.info('[IPFS] connected')
        this.recoTime = 1
      })
      .catch(() => this.reconnect())
  }

  reconnect() {
    logger.error(`[IPFS] attempting to reconnect in ${this.recoTime} seconds`)
    if (this.recoTime < MAX_RECO_TIME) {
      ++this.recoTime
    }
    return Promise.delay(this.recoTime * 1000)
      .then(() => this.connect())
  }

  addRelative(filePath) {
    return this.ready()
      .then(() => this.add(usrFile.fullPathStoreDir() + filePath))
  }

  add(filePath) {
    return this.ready()
      .then(() => this.node.add(filePath))
      .catch(() => this.reconnect().then(() => {
        logger.debug('adding again ' + filePath)
        this.add(filePath)
      }))
  }

  ready() {
    return this.node.id()
  }

  get(hash) {
    let data = []

    return this.ready()
      .then(() => this.node.cat(hash))
      .then((res) => new Promise((resolve, reject) => {
        res.on('end', () => resolve(Buffer.concat(data)))
        res.on('data', (chunk) => data.push(chunk))
        res.on('close', () => reject())
        res.on('error', () => reject())
      }))
      .catch(() => {
        return this.connect()
          .then(() => this.get(hash))
          .catch((err) => logger.debug('HASH RETRY: ' + err))
      })
  }
}
