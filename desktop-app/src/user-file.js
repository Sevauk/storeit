import * as fs from 'fs'
import * as path from 'path'
import {logger} from '../lib/log.js'
var rimraf = require('rimraf') // SORRY :(

let storeDir = './storeit'
let fullPathStoreDir = path.resolve(storeDir)

let makeFullPath = (filePath) => path.join(storeDir, filePath)

const makeSubDirs = (p) => new Promise((resolve) => {

  const eachDir = p.split(path.sep)
  let currentPath = storeDir
  for (let i = 0; i < eachDir.length - 1; i++) {

    currentPath += eachDir[i] + path.sep
    try {
      fs.mkdirSync(currentPath)
    }
    catch (e) {
    }
  }
  resolve()
})

let dirCreate = (dirPath) => new Promise((resolve) => {

  const fsPath = makeFullPath(dirPath)
  return makeSubDirs(dirPath)
    .then(() =>
      fs.mkdir(fsPath, (err) => !err || err.code === 'EEXIST' ?
        resolve({path: dirPath, isDir: true}) : resolve(err)
    ))
    .catch((err) => logger.error(err))
})

let fileCreate = (filePath, data) => new Promise((resolve, reject) => {

  const fsPath = makeFullPath(filePath)
  return makeSubDirs(filePath)
    .then(() => {
      return fs.writeFile(fsPath, data, (err) => !err ?
        resolve({path: filePath, data}) : reject(err)
      )
    }
    )
})

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
  setTimeout(() => ignoreSet.delete(file), 20000000)
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
