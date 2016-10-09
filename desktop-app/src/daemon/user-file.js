import * as fs from 'fs'
import * as path from 'path'

import del from 'del'

import {FileObj} from '../../lib/protocol-objects.js'
import settings from './settings'

Promise.promisifyAll(fs)

const storePath = p => '/' + path.relative(settings.getStoreDir(), p)
const absolutePath = (p='') => path.join(settings.getStoreDir(), p)

const dirCreate = (dirPath) => {
  const subdirs = dirPath.split('/')

  const makeSubdirs = (currPath, i=0) => {
    return fs.mkdirAsync(currPath)
      .catch((err) => {
        if (err.code !== 'EEXIST') throw err
      })
      .then(() => {
        if (i >= subdirs.length) return Promise.resolve()
        return makeSubdirs(path.join(currPath, subdirs[i]), i + 1)
      })
  }
  return makeSubdirs(settings.getStoreDir())
    .then(() => ({path: dirPath, isDir: true}))
}

const fileCreate = (filePath, data) => {
  const fsPath = absolutePath(filePath)
  return dirCreate(path.dirname(filePath))
    .then(() => fs.writeFileAsync(fsPath, data))
    .then(() => ({path: fsPath, data}))
}

const fileDelete = (filePath) => del(absolutePath(filePath), {force: true})
  .then(() => ({path: filePath}))

const fileMove = (src, dst) =>
  fs.renameAsync(absolutePath(src), absolutePath(dst))
    .then(() => ({src, dst}))

const fileExists = (filePath) =>
  fs.accessAsync(absolutePath(filePath), fs.constants.F_OK)

const chunkPath = hash => storePath(path.join(settings.getHostDir(), hash))
const chunkCreate = (ipfsHash, data) => fileCreate(chunkPath(ipfsHash), data)
const chunkDelete = hash => fileDelete(chunkPath(hash))

const clear = (keepChunks=false) => {
  const store = settings.getStoreDir()
  let keep = [store]
  if (keepChunks) keep.push(settings.getHostDir())
  keep = keep.map(file => `!${file}`)
  return del([`${store}/**`, `${store}/.**`, ...keep], {force: true})
}

const generateTree = (hashFunc, filePath='') => {
  const absPath = absolutePath(filePath)
  return fs.statAsync(absPath)
    .then(stat => {
      if (stat.isDirectory()) {
        return fs.readdirAsync(absPath)
          .map(file => generateTree(hashFunc, path.join(filePath, file)))
          .then(files => new FileObj(filePath, null, files))
      }
      return Promise.resolve(hashFunc(filePath))
        .then(hash => new FileObj(filePath, hash))
    })
}

const getHostedChunks = () => fs.readdirAsync(settings.getHostDir())

export default {
  absolutePath,
  storePath,
  dirCreate,
  create: fileCreate,
  exists: fileExists,
  del: fileDelete,
  chunkPath,
  chunkCreate,
  chunkDel: chunkDelete,
  move: fileMove,
  clear,
  generateTree,
  getHostedChunks
}
