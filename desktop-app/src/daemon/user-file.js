import * as fs from 'fs'
import * as path from 'path'

import del from 'del'

import {FileObj} from '../../lib/protocol-objects.js'
import settings from './settings'

Promise.promisifyAll(fs)

const storePath = p => '/' + path
  .relative(settings.getStoreDir(), p)
  .replace(/\\/g, '/')
const absolutePath = (p='') => path.join(settings.getStoreDir(), p)

const dirCreate = (dirPath) => {
  const subdirs = dirPath.split('/')

  const makeSubdirs = (currPath, i=0) => {
    return fs.mkdirAsync(currPath)
      .catch((err) => {
        if (err.code !== 'EEXIST') throw err
      })
      .then(() => {
        if (i < subdirs.length)
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
  .replace(/\\/g, '/')
const chunkCreate = (ipfsHash, data) => fileCreate(chunkPath(ipfsHash), data)
const chunkDelete = hash => fileDelete(chunkPath(hash))

const clear = (keepChunks=false) => {
  const store = settings.getStoreDir()
  let keep = [store]
  if (keepChunks) keep.push(settings.getHostDir())
  keep = keep.map(file => `!${file}`)
  return del([`${store}/**`, `${store}/.**`, ...keep], {force: true})
}

const generateTree = (hashFunc, filePath='', rec=true) => {
  const absPath = absolutePath(filePath)

  const arrayToMap = (entries) => {
    const ret = {}
    entries.forEach(file => ret[path.basename(file.path)] = file)
    return ret
  }
  const normalizePath = (dir, file) => path.join(dir, file).replace(/\\/g, '/')

  return fs.statAsync(absPath)
    .then(stat => {
      if (stat.isDirectory()) {
        // QUICKFIX macos watcher issue
        if (!rec) return Promise.resolve(new FileObj(storePath(absPath), null, {}))

        return fs.readdirAsync(absPath)
          .map(entry => generateTree(hashFunc, normalizePath(filePath, entry)))
          .then(arrayToMap)
          .then(files => new FileObj(storePath(absPath), null, files))
      }
      else return Promise.resolve(hashFunc(filePath))
        .then(hash => new FileObj(storePath(absPath), hash))
    })
}

const getHostedChunks = () => {
  const p = storePath(settings.getHostDir())
  return fileExists(p)
    .then(() => fs.readdirAsync(settings.getHostDir()))
    .catch(() => [])
}

const addSubDir = (dir, fileName) => {
  const storeitPath = path.join(dir.path, fileName)
  return fs.statAsync(absolutePath(storeitPath))
    .then(stats => {
      if (stats.isDirectory()) dir.files[fileName] = new FileObj(storeitPath, null)
    })
}

// WIP
const getUnknownFiles = (dir) => {
  // let newFiles
  // let res = []
  return fs.readdirAsync(absolutePath(dir.path))
    // .tap(() => console.log(''))
    // .tap(() => console.log(''))
    // .tap(files => console.log('files:', files))
    //
    // .filter(fileName => dir.files == null || dir.files[fileName] == null)
    // .tap(files => newFiles = files)
    // .tap(() => console.log('new files:', newFiles))
    //
    // .each(fileName => res.push(path.join(dir.path, fileName)))
    // .then(() => newFiles)
    // .tap(() => console.log('res:', res))
    //
    // .each(fileName => addSubDir(fileName))
    //
    // .tap(() => console.log('dir:', dir))
    // .then(() => dir.files ? Object.keys(dir.files) : [])
    // .map(fileName => dir.files[fileName])
    // .filter(file => file.isDir)
    // .each(file => getUnknownFiles(file, res))
}

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
  getHostedChunks,
  getUnknownFiles
}
