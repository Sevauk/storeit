import ipfs from 'ipfs-api'

import logger from '../../lib/log'
import userFile from './user-file.js'

// the filePath parameters should be relative to the synchronized directory's root
const MAX_RECO_TIME = 4

export default class IPFSNode {
  constructor(opts={}) {
    this.connecting = false
    this.recoTime = 1
    this.downloading = {}
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
    return ipfs.rm ? ipfs.rm(hash)  : Promise.resolve()
  }

  // progressCb(filePath, hash, totalSize, downloadedSize, progressPercentage)
  get(filePath, hash, progressCb) {

    logger.debug('[IPFS] GET ' + hash)

    if (this.checkForAlreadyDownloading(hash, filePath))
      return Promise.reject()

    let data = []

    return this.ready()
      .then(() => this.node.cat(hash))
      .then((res) => new Promise((resolve, reject) => {

        this.downloading[filePath] = res
        let totalSize = null
        let downloadedSize = 0
        let done = false

        this.node.object.stat(hash)
          .then((res) => {
            totalSize = res.CumulativeSize
          })
          .catch((err) => logger.error(`[IPFS] object stat failed ${err}`))

        res.on('end', () => {
          done = true
          return resolve(Buffer.concat(data))
        })
        res.on('data', (chunk) => {
          downloadedSize += chunk.length
          data.push(chunk)
        })

        const doneReject = () => {
          done = true
          return reject()
        }

        res.on('close', () => doneReject())
        res.on('error', () => doneReject())

        const tickProgress = () => {
          Promise.delay(500).then(() => {
            let progressPercentage = totalSize ? downloadedSize * 100 / totalSize : 0
            progressCb(filePath, hash, totalSize, downloadedSize, progressPercentage)
            if (!done)
              tickProgress()
          })
        }

        if (progressCb)
          tickProgress()

      }))
      .catch((e) => this.reconnect().then(() => {
        logger.error(`[IPFS] ${hash} download failed (${e}). Retrying`)
        return this.get(filePath, hash)
      }))
  }

  // progressCb(filePath, hash, totalSize, downloadedSize, progressPercentage)
  download(filePath, ipfsHash, isChunk=false, progressCb) {
    let log = isChunk ? logger.debug : logger.info
    log(`[SYNC:download] file: ${filePath} [${ipfsHash}]`)

    return this.get(filePath, ipfsHash, progressCb)
      .then(buf => userFile.create(filePath, buf))
      .delay(500)  // QUCIK FIX, FIXME
      .then(() => {
        delete this.downloading[filePath]
        return this.add(filePath)
      })
      .tap(() => log(`[SYNC:success] file: ${filePath} [${ipfsHash}]`))
      .catch((err) => log(`[IPFS] get interrupted (${err})`))
  }

  // download(ipfsHash, filePath) {
  //   const log = filePath ? logger.info : logger.debug
  //   const type = filePath ? 'file' : 'chunk'
  //   if (!filePath) filePath = userFile.chunkPath(ipfsHash)
  //
  //   log(`[SYNC:download] ${type}: ${filePath} [${ipfsHash}]`)
  //   return this.get(ipfsHash)
  //     .then(buf => userFile.create(filePath, buf))
  //     .then(() => this.add(filePath))
  //     .tap(() => log(`[SYNC:success] ${type}: ${filePath} [${ipfsHash}]`))
  // }
}
