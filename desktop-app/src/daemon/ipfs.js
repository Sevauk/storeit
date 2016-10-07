import ipfs from 'ipfs-api'

import logger from '../../lib/log'
import userFile from './user-file.js'

const MAX_RECO_TIME = 4

export default class IPFSNode {
  constructor(opts={}) {
    this.connecting = false
    this.recoTime = 1
    this.recoUnit = opts.recoUnit || 1000
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
    const sec = this.recoTime * this.recoUnit / 1000
    logger.error(`[IPFS] attempting to reconnect in ${sec} seconds`)
    let done = Promise.delay(this.recoTime * this.recoUnit)
      .then(() => this.connect())
    if (this.recoTime < MAX_RECO_TIME) ++this.recoTime
    return done
  }

  ready() {
    return this.node.id()
  }

  getFileHash(filePath) {
    return this.add(filePath).then(res => res[0].Hash)
  }

  hashMatch(filePath, ipfsHash) {
    return this.getFileHash(filePath).then(hash => hash === ipfsHash)
  }

  add(filePath) {
    return this.ready()
      .then(() => this.node.add(userFile.absolutePath(filePath)))
      .catch(() => this.reconnect().then(() => {
        logger.error(`[SYNC:fail] file: ${filePath}. Retrying`)
        return this.add(filePath)
      }))
  }

  rm(hash) {
    if (ipfs.rm != null) return ipfs.rm(hash)
    return Promise.resolve()
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

  download(ipfsHash, filePath) {
    const log = filePath ? logger.info : logger.debug
    const type = filePath ? 'file' : 'chunk'
    if (!filePath) filePath = userFile.chunkPath(ipfsHash)

    log(`[SYNC:download] ${type}: ${filePath} [${ipfsHash}]`)
    return this.get(ipfsHash)
      .then(buf => userFile.create(filePath, buf))
      .then(() => this.add(filePath))
      .tap(() => log(`[SYNC:success] ${type}: ${filePath} [${ipfsHash}]`))
  }
}
