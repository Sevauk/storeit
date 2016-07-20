import ipfs from 'ipfs-api'
import {logger} from '../lib/log'
import usrFile from './user-file.js'

const MAX_RECO_TIME = 4

export default class IPFSNode {
  constructor() {
    this.connecting = false
    this.recoTime = 1
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

    return new Promise((resolve) => {
      logger.error(`[IPFS] attempting to reconnect in ${this.recoTime} seconds`)
      setTimeout(() => {
        this.connect()
        .then(() => resolve())
      }, this.recoTime * 1000)

      if (this.recoTime < MAX_RECO_TIME) {
        ++this.recoTime
      }
    })
  }

  addRelative(filePath) {
    return this.ready()
      .then(() => this.add(usrFile.fullPathStoreDir + filePath))
  }

  add(filePath) {
    return this.ready()
      .then(() => this.node.add(filePath))
  }

  ready() {
    return this.node.id()
  }

  get(hash) {
    let data = []

    return this.ready()
      .then(() => this.node.cat(hash))
      .then((res) => new Promise((resolve) => {
        res.on('end', () => resolve(Buffer.concat(data)))
        res.on('data', (chunk) => data.push(chunk))
      }))
      .catch((err) => {
        logger.error(err)
        return this.connect()
          .then(() => {
            logger.debug('GETTING ' + hash + ' again')
            this.get(hash)
          })
      })
  }
}
