import ipfs from 'ipfs-api'

import logger from '../../lib/log'
import userFile from './user-file.js'

const MAX_RECO_TIME = 4

export default class IPFSNode {
  constructor(opts={}) {
    this.connecting = false
    this.recoTime = 1
    this.resources = {}
    this.recoUnit = opts.recoUnit || 1000
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

  close() {
    this.node = null
  }

  ready() {
    return this.node.id()
  }

  // TODO: this should be optimized. add is overkill
  getFileHash(filePath) {
    const opt = {
      // 'only-hash': true,
      // 'recursive': false
    }

    return this.add(filePath, opt)
      // .tap(res => logger.debug(logger.toJson(res)))
      .then(res => res[0].Hash)
  }

  hashMatch(filePath, ipfsHash) {
    return this.getFileHash(filePath).then(hash => hash === ipfsHash)
  }

  add(filePath, opt) {
    return this.ready()
      .then(() => this.node.add(userFile.absolutePath(filePath), opt))
      .catch((e) => this.reconnect().then(() => {
        logger.error(`[SYNC:fail] file: ${filePath} (${e}). Retrying`)
        return this.add(filePath)
      }))
  }

  rm(hash) {
    return ipfs.rm ? ipfs.rm(hash) : Promise.resolve()
  }

  get(hash, id, notify) {
    let data = []
    let downloadedSize = 0

    return this.getResource(hash, id)
      .then(res => new Promise((resolve, reject) => {
        const fail = (e) => reject(new Error(`[IPFS]: download failed ${e}`))
        if (notify) notify(0)

        res.on('close', e => fail(e))
        res.on('error', e => fail(e))
        res.on('data', (chunk) => {
          downloadedSize += chunk.length
          data.push(chunk)
          if (notify) notify(downloadedSize)
        })
        res.on('end', () => {
          this.freeResource(hash, id)
          resolve(Buffer.concat(data))
        })
      }))
      .catch((e) => this.reconnect().then(() => {
        logger.error(`[IPFS] ${e}. Retrying`)
        return this.get(hash, id, notify)
      }))
  }

  download(ipfsHash, filePath, progressCb) {
    let file = {
      ipfsHash,
      path: filePath || userFile.chunkPath(ipfsHash),
      size: null,
      type: filePath ? 'file' : 'chunk'
    }

    const log = file.type === 'chunk' ? logger.debug : logger.info
    log(`[SYNC:download] ${file.type}: ${file.path} [${ipfsHash}]`)
    return this.ready()
      .then(() => this.getResourceSize(ipfsHash))
      .then(size => file.size = size)
      .then(() => this.get(ipfsHash, file.path, (currSize) =>
        this.downloadStatusUpdate(file, currSize, progressCb)
      ))
      .tap(() => this.downloadStatusUpdate(file, file.size, progressCb)) // quickfix
      .then(buf => userFile.create(file.path, buf))
      .then(() => this.add(file.path))
      .tap(() => log(`[SYNC:success] ${file.type}: ${file.path} [${ipfsHash}]`))
  }

  downloadStatusUpdate(file, downloadedSize, progressCb) {
    const percentage = downloadedSize / file.size || 0
    if (progressCb != null) progressCb(percentage * 100, file)
  }

  getResourceSize(ipfsHash) {
    return this.node.object.stat(ipfsHash)
      .then(res => res.CumulativeSize)
  }

  getResource(hash, id) {
    return this.ready()
      // .then(() => this.cancelPending(id, hash))
      .then(() => this.node.cat(hash))
      // .then(() => console.log('get resource'))
      // .catch(() => console.error('err: get resource'))
      .tap(res => {
        if (id != null) this.resources[id] = res
      })
  }

  freeResource(id) {
    if (id != null) delete this.resources[id]
  }

  // TODO add tests
  cancelPending(filePath, hash) {
    if (filePath in this.resources) {

      logger.debug(`[IPFS] cancelling previous get for ${filePath}`)

      const obj = this.resources[filePath]
      if (obj.close)
        obj.close()
      else if (obj === hash)
        return true
    }
    return false
  }
}
