import * as fs from 'fs'
import * as path from 'path'

let storeDir = './storeit'
let fullPathStoreDir = path.resolve(storeDir)

let makeFullPath = (filePath) => path.join(storeDir, filePath)

let dirCreate = (dirPath) => new Promise((resolve) =>
  fs.mkdir(makeFullPath(dirPath), (err) => !err || err.code === 'EEXIST' ?
    resolve({path: dirPath, isDir: true}) : resolve(err)
  )
)

let fileCreate = (filePath, data) => new Promise((resolve, reject) =>
  fs.writeFile(makeFullPath(filePath), data, (err) => !err ?
    resolve({path: filePath, data}) : reject(err)
  )
)

let fileDelete = (filePath) => new Promise((resolve, reject) =>
  fs.unlink(makeFullPath(filePath), (err) => !err ?
    resolve({path: filePath}) : reject(err)
  )
)


let fileMove = (src, dst) => new Promise((resolve, reject) =>
  fs.rename(makeFullPath(src), makeFullPath(dst), (err) => !err ?
    resolve({src, dst}) : reject(err)
  )
)

const ignoreSet = new Set()

const ignore = (file) => {
  ignoreSet.add(file)
  setTimeout(() => {
    ignoreSet.delete(file)
  }, 20000000)
}

const unignore = (file) => {
  ignoreSet.delete(file)
}

const isIgnored = (file) => {
  return ignoreSet.has(file)
}

export default {
  setStoreDir(dirPath) {
    storeDir = dirPath
  },
  getStoreDir() {
    return storeDir
  },
  ignoreSet,
  ignore,
  unignore,
  isIgnored,
  fullPath: makeFullPath,
  dirCreate,
  create: fileCreate,
  del: fileDelete,
  move: fileMove,
  fullPathStoreDir
}
