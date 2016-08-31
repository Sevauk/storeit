import * as fs from 'fs'
import * as path from 'path'

import del from 'del'

import logger from '../../lib/log.js'
import settings from './settings'

Promise.promisifyAll(fs)

let fullPathStoreDir = () => path.resolve(settings.getStoreDir())

let makeFullPath = (filePath) => path.join(settings.getStoreDir(), filePath)

const makeSubDirs = (p) => {
  const eachDir = p.split(path.sep)
  let currentPath = settings.getStoreDir()

  return Promise.map(eachDir, (dir) => {
    currentPath = path.join(currentPath, dir)
    return fs.mkdirAsync(currentPath)
      .catch((err) => {
        if (err.code !== 'EEXIST') throw err
      })
  })
}

let dirCreate = (dirPath) => {
  const dir = {path: dirPath, isDir: true}
  return makeSubDirs(dirPath)
    .then(() => fs.mkdirAsync(makeFullPath(dirPath)))
    .then(() => dir)
    .catch((err) => {
      if (err.code === 'EEXIST') return dir
      else throw err
    })
    .catch((err) => logger.error(err))
}

let fileCreate = (filePath, data) => {
  const fsPath = makeFullPath(filePath)
  return makeSubDirs(makeFullPath(filePath))
    .then(() => fs.writeFileAsync(fsPath, data))
    .then(() => ({path: filePath, data}))
}

let fileDelete = (filePath) => del(makeFullPath(filePath))

let fileMove = (src, dst) =>
  fs.renameAsync(makeFullPath(src), makeFullPath(dst))
    .then(() => ({src, dst}))

const ignoreSet = new Set()

const ignore = (file) => {
  ignoreSet.add(file)
  Promise.delay(20000000)
    .then(() => ignoreSet.delete(file))
}

const unignore = (file) => ignoreSet.delete(file)
const isIgnored = (file) => ignoreSet.has(file)
const toStoreitPath = (p) => '/' + path.relative(settings.getStoreDir(), p)

export default {
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
