import * as fs from 'fs'
import {logger} from './log.js'
import * as api from './protocol-objects.js'

const readmeHash = 'Qmco5NmRNMit3V2u3whKmMAFaH4tVX4jPnkwZFRdsb4dtT'
export let storeDir = './storeit'
export let home = // TODO: get this from server response to JOIN instead
  api.makeFileObj('/', null, {
    'readme.txt': api.makeFileObj('/readme.txt', readmeHash)
  })

let makeInfo = (path, kind) => {
  return {
    path,
    metadata: 'uninplemented for now',
    contentHash: 'hache',
    kind,
    files: []
  }
}

let dirToJson = (filename) => {

  let stats = fs.lstatSync(filename)

  let info = makeInfo(filename, stats.isDirectory ? 0 : 1)

  if (stats.isDirectory()) {
    info.files = fs.readdirSync(filename).map((child) => {
      return dirToJson(filename + '/' + child)
    })
  }

  return info
}

let mkdirUser = () => {
  fs.mkdir(storeDir, (err) => {
    if (err) {
      logger.warn('cannot mkdir user dir')
    }
  })
}

export let makeUserTree = () => {
  mkdirUser()
  let dir = dirToJson(storeDir)
  dir.path = '/'
  return dir
}
