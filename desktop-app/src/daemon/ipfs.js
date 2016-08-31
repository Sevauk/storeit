import ipfs from 'ipfs-api'

import logger from '../../lib/log'
import userFile from './user-file.js'

const MAX_RECO_TIME = 4

export default class IPFSNode {
  constructor() {
    this.connecting = false
    this.recoTime = 1
    this.connect()
  }

  connect() {
    const {IPFS_ADDR, IPFS_PORT} = process.env
    this.node = ipfs(`/ip4/${IPFS_ADDR}/tcp/${IPFS_PORT}`)

    return this.ready()
      .tap(() => logger.info('[IPFS] connected'))
      .then(() => this.recoTime = 1)
      .catch(() => this.reconnect())
  }

  reconnect() {
    logger.error(`[IPFS] attempting to reconnect in ${this.recoTime} seconds`)
    let done = Promise.delay(this.recoTime * 1000)
      .then(() => this.connect())
    if (this.recoTime < MAX_RECO_TIME) ++this.recoTime
    return done
  }

  ready() {
    return this.node.id()
  }

  isInStore(filePath, ipfsHash) {
    return this.add(filePath)
      .then(hash => hash[0].Hash === ipfsHash)
  }

  download(filePath, ipfsHash) {
    logger.info(`[DL] file: ${filePath} [${ipfsHash}]`)
    return this.get(ipfsHash)
      .then(buf => userFile.create(filePath, buf))
      .delay(500)  // QUCIK FIX, FIXME
      .then(() => this.ipfs.add(filePath))
  }

  add(filePath) {
    return this.ready()
      .then(() => this.node.add(userFile.absolutePath(filePath)))
      .catch(() => this.reconnect().then(() => {
        logger.error(`[IPFS] ${filePath} sync failed. Retrying`)
        return this.add(filePath)
      }))
  }

  get(hash) {
    let data = []

    logger.info(`[IPFS] downloading file ${hash} from ipfs`)
    return this.ready()
      .then(() => this.node.cat(hash))
      .then((res) => new Promise((resolve, reject) => {
        res.on('end', () => resolve(Buffer.concat(data)))
        res.on('data', (chunk) => data.push(chunk))
        res.on('close', () => reject())
        res.on('error', () => reject())
      }))
      .tap(() => logger.info(`[IPFS] file ${hash} downloaded`))
      .catch(() => this.reconnect().then(() => {
        logger.error(`[IPFS] ${hash} download failed. Retrying`)
        return this.get(hash)
      }))
  }
}
