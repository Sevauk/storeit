import * as path from 'path'

export const setTree = (home, destPath, action) => {

    if (home === undefined) {
      logger.error('home has not loaded')
    }

    const pathToFile = destPath.split(path.sep)
    const stepInto = (path, tree) => {

      if (pathToFile.length === 1) {
        return action(tree, pathToFile[0])
      }

      const name = pathToFile.shift()
      return stepInto(pathToFile, tree.files[name])
    }
    pathToFile.shift()
    return stepInto(pathToFile, home)
  }
