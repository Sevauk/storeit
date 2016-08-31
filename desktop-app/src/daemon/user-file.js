import * as fs from 'fs'
import * as path from 'path'

import del from 'del'

import logger from '../../lib/log.js'
import {FileObj} from '../../lib/protocol-objects.js'
import * as ipfs from './ipfs'
import settings from './settings'

Promise.promisifyAll(fs)

const storePath = (p) => '/' + path.relative(settings.getStoreDir(), p)
const absolutePath = (filePath) => path.join(settings.getStoreDir(), filePath)

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

const dirCreate = (dirPath) => {
  const dir = {path: dirPath, isDir: true}
  return makeSubDirs(dirPath)
    .then(() => fs.mkdirAsync(absolutePath(dirPath)))
    .then(() => dir)
    .catch((err) => {
      if (err.code === 'EEXIST') return dir
      else throw err
    })
    .catch((err) => logger.error(err))
}

const fileCreate = (filePath, data) => {
  const fsPath = absolutePath(filePath)
  return makeSubDirs(absolutePath(filePath))
    .then(() => fs.writeFileAsync(fsPath, data))
    .then(() => ({path: filePath, data}))
}

const fileExists = (filePath) =>
  fs.accessAsync(absolutePath(filePath), fs.constants.F_OK)

const fileDelete = (filePath) => del(absolutePath(filePath))

const fileMove = (src, dst) =>
  fs.renameAsync(absolutePath(src), absolutePath(dst))
    .then(() => ({src, dst}))

const generateTree = (filePath) => {
  const objPath = storePath(filePath)
  logger.debug('path:', filePath)
  logger.debug('storePath:', objPath)
  return fs.statAsync(filePath)
    .then((stat) => {
      if (stat.isDirectory()) {
        return fs.readdirAsync(filePath)
          .map(file => generateTree(path.join(filePath, file)))
          .then(files => new FileObj(objPath, null, files))
      }
      return ipfs.getFileHash(objPath)
        .then(hash => new FileObj(objPath, hash))
    })
}

export default {
  absolutePath,
  storePath,
  dirCreate,
  create: fileCreate,
  exists: fileExists,
  del: fileDelete,
  move: fileMove,
  generateTree
}
