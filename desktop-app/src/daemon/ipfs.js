import ipfs from 'ipfs-api'

import logger from '../../lib/log'
import userFile from './user-file.js'

// the filePath parameters should be relative to the synchronized directory's root
const MAX_RECO_TIME = 4
let singleton

class IPFSNode {
  constructor() {
    this.connecting = false
    this.recoTime = 1
    this.connect()
    this.downloading = {}
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

  // TODO: this should be optimized. add is overkill
  getFileHash(filePath) {

    const opt = {}
    opt['only-hash'] = true
    opt['recursive'] = false
    return this.add(filePath, opt).then(res => {
      logger.debug(JSON.stringify(res, null, 2))
      return res[0].Hash
    })
  }

  hashMatch(filePath, ipfsHash) {
    return this.add(filePath)
      .then(hash => hash[0].Hash === ipfsHash)
  }

  add(filePath, opt) {
    return this.ready()
      .then(() => this.node.add(userFile.absolutePath(filePath), opt))
      .catch((e) => this.reconnect().then(() => {
        logger.error(`[SYNC:fail] file: ${filePath} (${e}). Retrying`)
        return this.add(filePath)
      }))
  }

  checkForAlreadyDownloading(hash, filePath) {

    if (!hash) {
      logger.error('empty hash given :o ')
      return Promise.reject()
    }

    if (filePath in this.downloading) {

      logger.debug(`[IPFS] cancelling previous get for ${filePath}`)

      const obj = this.downloading[filePath]
      if (obj.close)
        obj.close()
      else if (obj === hash) // we are already downloading this hash
        return Promise.reject()
    }

    this.downloading[filePath] = hash // store the hash and when the download starts store the stream object (see a few lines below)

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

  rm(hash) {
    return ipfs.rm ? ipfs.rm(hash)  : Promise.resolve()
  }

  downloadChunk(hash) {
    return this.download(userFile.chunkPath(hash), hash, true)
  }

  rmChunk(hash) {
    return this.rm(hash).then(() => userFile.chunkDel(hash))
  }

  // @Sevauk: not sure I understood this one, correct this if I'm wrong
  // downloadChunk(hash) {
  //   if (hash.substr(0, 2) !== 'Qm')
  //     throw new Error('bad IPFS Hash ' + hash)
  //   return this.get(hash)
  //     .then((data) => fs.writeFile(ipfsStore + hash, data))
  //     // TODO: ipfs add directly instead
  // }
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
