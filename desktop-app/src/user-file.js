import * as fs from 'fs'
import * as path from 'path'
var rimraf = require('rimraf') // SORRY :(

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

let fileDelete = (filePath) => new Promise((resolve, reject) => {

  const fPath = storeDir + filePath
  rimraf(fPath, (err) => !err ? resolve({path: fPath}) : reject(err))
})


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

const unignore = (file) => ignoreSet.delete(file)
const isIgnored = (file) => ignoreSet.has(file)
const toStoreitPath = (p) => '/' + path.relative(storeDir, p)

export default {
  setStoreDir(dirPath) {
    storeDir = dirPath
  },
  getStoreDir() {
    return storeDir
  },
  toStoreitPath,
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
