import * as fs from 'fs'
import * as path from 'path'

import del from 'del'

import {FileObj} from '../../lib/protocol-objects.js'
import * as ipfs from './ipfs'
import settings from './settings'

Promise.promisifyAll(fs)

const storePath = (p) => '/' + path.relative(settings.getStoreDir(), p)
const absolutePath = (filePath) => path.join(settings.getStoreDir(), filePath)

const dirCreate = (dirPath) => {
  let currPath = settings.getStoreDir()

  return Promise.map(dirPath.split(path.sep), (dir) => {
    currPath = path.join(currPath, dir)
    return fs.mkdirAsync(currPath).catch((err) => {
      if (err.code !== 'EEXIST') throw err
    })
  }).then(() => ({path: dirPath, isDir: true}))
}

const fileCreate = (filePath, data) => {
  const fsPath = absolutePath(filePath)
  return dirCreate(path.dirname(filePath))
    .then(() => fs.writeFileAsync(fsPath, data))
    .then(() => ({path: filePath, data}))
}

const fileExists = (filePath) =>
  fs.accessAsync(absolutePath(filePath), fs.constants.F_OK)

const fileDelete = (filePath) => del(absolutePath(filePath), {force: true})
  .then(() => ({path: filePath}))

const fileMove = (src, dst) =>
  fs.renameAsync(absolutePath(src), absolutePath(dst))
    .then(() => ({src, dst}))

const generateTree = (filePath) => {
  const absPath = absolutePath(filePath)
  return fs.statAsync(absPath)
    .then(stat => {
      if (stat.isDirectory()) {
        return fs.readdirAsync(absPath)
          .map(file => generateTree(path.join(filePath, file)))
          .then(files => new FileObj(filePath, null, files))
      }
      return ipfs.getFileHash(filePath)
        .then(hash => new FileObj(filePath, hash))
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
