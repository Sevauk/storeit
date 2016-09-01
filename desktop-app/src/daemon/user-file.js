import * as fs from 'fs'
import * as path from 'path'
import {logger} from '../lib/log.js'
import cmd from './main.js'
var rimraf = require('rimraf') // SORRY :(

const storeitPathToFSPath = (filePath) => path.join(cmd.store, filePath)

const makeSubDirs = (p) => new Promise((resolve) => {

  const eachDir = p.split(path.sep)
  let currentPath = cmd.store
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

  const fsPath = storeitPathToFSPath(dirPath)
  return makeSubDirs(dirPath)
    .then(() =>
      fs.mkdir(fsPath, (err) => !err || err.code === 'EEXIST' ?
        resolve({path: dirPath, isDir: true}) : resolve(err)
    ))
    .catch((err) => logger.error(err))
})

let fileCreate = (filePath, data) => new Promise((resolve, reject) => {

  const fsPath = storeitPathToFSPath(filePath)
  return makeSubDirs(filePath)
    .then(() => {
      return fs.writeFile(fsPath, data, (err) => !err ?
        resolve({path: filePath, data}) : reject(err)
      )
    }
    )
})

let fileDelete = (filePath) => new Promise((resolve, reject) => {

  const fPath = cmd.store + filePath
  rimraf(fPath, (err) => !err ? resolve({path: fPath}) : reject(err))
})


let fileMove = (src, dst) => new Promise((resolve, reject) => {
  const fullSrc = storeitPathToFSPath(src)
  const fullDst = storeitPathToFSPath(dst)
  return fs.rename(fullSrc, fullDst, (err) => !err ? resolve({src, dst}) : reject(err))
})

const ignoreSet = new Set()

const ignore = (file) => {
  ignoreSet.add(file)
  setTimeout(() => ignoreSet.delete(file), 20000000)
}

const unignore = (file) => ignoreSet.delete(file)
const isIgnored = (file) => ignoreSet.has(file)
const toStoreitPath = (p) => '/' + path.relative(cmd.store, p)

export default {
  storeitPathToFSPath,
  toStoreitPath,
  ignoreSet,
  ignore,
  unignore,
  isIgnored,
  dirCreate,
  create: fileCreate,
  del: fileDelete,
  move: fileMove,
}
