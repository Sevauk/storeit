import * as path from 'path'
import * as api from './protocol-objects.js'
import * as fs from 'fs'
import {logger} from './log.js'

export const setTree = (home, destPath, action) => {

  if (home === undefined) {
    logger.error('home has not loaded')
    return api.ApiError.SERVERERROR
  }

  if (destPath === undefined) {
    logger.debug('invalid tree')
    return api.ApiError.BADTREE
  }

  const pathToFile = destPath.split(path.sep)
  const stepInto = (path, tree) => {


    if (pathToFile.length === 1) {

      if (!tree)
        return api.errWithStack(api.ApiError.BADTREE)

      return action(tree, pathToFile[0])
    }

    if (!tree)
      return api.errWithStack(api.ApiError.BADTREE)


    const name = pathToFile.shift()

    if (!tree.files) {
      logger.debug(`there is no ${name} in ${tree.path}. Generating`)
      tree.files = {}
    }

    if (!tree.files[name]) {
      const dirName = `${tree.path}/${name}`
      logger.debug(`generating ${dirName}`)
      tree.files[name] = new api.FileObj(dirName)
    }

    return stepInto(pathToFile, tree.files[name])
  }
  pathToFile.shift()
  return stepInto(pathToFile, home)
}

export const forEachHash = (tree, handler) => {

  if (tree.IPFSHash)
    handler(tree.IPFSHash)

  if (tree.files)
    // TODO: make Object.values work with babel
    for (const file of Object.keys(tree.files))
      forEachHash(tree.files[file], handler)
}
