import * as path from 'path'
import * as api from './protocol-objects.js'

export const setTree = (home, destPath, action) => {

    if (home === undefined) {
      logger.error('home has not loaded')
      return
    }

    const pathToFile = destPath.split(path.sep)
    const stepInto = (path, tree) => {


      if (pathToFile.length === 1) {
        return action(tree, pathToFile[0])
      }

      if (!tree)
        return api.errWithStack(api.ApiError.BADTREE)

      const name = pathToFile.shift()
      return stepInto(pathToFile, tree.files[name])
    }
    pathToFile.shift()
    return stepInto(pathToFile, home)
  }
