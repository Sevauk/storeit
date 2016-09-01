import ipfs from 'ipfs-api'

import logger from '../../lib/log'
import userFile from './user-file.js'

const MAX_RECO_TIME = 4
let singleton

class IPFSNode {
  constructor() {
    this.connecting = false
    this.recoTime = 1
    this.connect()
  }

  connect() {
    const {IPFS_ADDR, IPFS_PORT} = process.env
    this.node = ipfs(`/ip4/${IPFS_ADDR}/tcp/${IPFS_PORT}`)

    return this.ready()
      .tap(() => logger.info('[IPFS] node connected'))
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

  download(filePath, ipfsHash) {
    logger.info(`[SYNC:download] file: ${filePath} [${ipfsHash}]`)
    return this.get(ipfsHash)
      .then(buf => userFile.create(filePath, buf))
      .delay(500)  // QUCIK FIX, FIXME
      .then(() => this.add(filePath))
      .tap(() => logger.info(`[SYNC:success] file: ${filePath} [${ipfsHash}]`))
  }

  getFileHash(filePath) {
    return this.add(filePath).then(res => res[0].Hash)
  }

  hashMatch(filePath, ipfsHash) {
    return this.add(filePath)
      .then(hash => hash[0].Hash === ipfsHash)
  }

  add(filePath) {
    return this.ready()
      .then(() => this.node.add(userFile.absolutePath(filePath)))
      .catch(() => this.reconnect().then(() => {
        logger.error(`[SYNC:fail] file: ${filePath}. Retrying`)
        return this.add(filePath)
      }))
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
      .catch(() => this.reconnect().then(() => {
        logger.error(`[IPFS] ${hash} download failed. Retrying`)
        return this.get(hash)
      }))
  }
}

export const createNode = () => {
  if (singleton == null)
    singleton = new IPFSNode
  else
    logger.warn('[IPFS] node already created')
  return singleton
}
export const getFileHash = filePath => {
  if (singleton == null) throw new Error('[IPFS] not instanciated')
  return singleton.getFileHash(filePath)
}
