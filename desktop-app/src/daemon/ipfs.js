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

  download(filePath, ipfsHash, isChunk=false) {
    let log = isChunk ? logger.debug : logger.info
    log(`[SYNC:download] file: ${filePath} [${ipfsHash}]`)

    return this.get(filePath, ipfsHash)
      .then(buf => userFile.create(filePath, buf))
      .delay(500)  // QUCIK FIX, FIXME
      .then(() => {
        delete this.downloading[filePath]
        return this.add(filePath)
      })
      .tap(() => log(`[SYNC:success] file: ${filePath} [${ipfsHash}]`))
      .catch((err) => log(`[IPFS] get interrupted (${err})`))
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

  downloadProgress(hash, totalSize, downloaded) {
    const advance = totalSize ? downloaded * 100 / totalSize : `${downloaded} bytes`
    logger.debug(`downloaded ${Math.round(advance)}% (${downloaded})`)
  }

  get(filePath, hash) {
    let data = []

    if (!hash) {
      logger.error('empty hash given :o ')
      return Promise.reject()
    }

    logger.debug('[IPFS] GET ' + hash)

    if (filePath in this.downloading) {

      logger.debug(`[IPFS] cancelling previous get for ${filePath}`)

      const obj = this.downloading[filePath]
      if (obj.close)
        obj.close()
      else if (obj === hash) // we are already downloading this hash
        return Promise.reject()
    }

    this.downloading[filePath] = hash // store the hash and when the download starts store the stream object (see a few lines below)

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
          setTimeout(() => {
            this.downloadProgress(hash, totalSize, downloadedSize)
            if (!done)
              tickProgress()
          }, 500)
        }

        tickProgress()

      }))
      .catch((e) => this.reconnect().then(() => {
        logger.error(`[IPFS] ${hash} download failed (${e}). Retrying`)
        return this.get(filePath, hash)
      }))
  }

  rm(hash) {
    if (ipfs.rm != null) return ipfs.rm(hash)
    return Promise.resolve()
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
