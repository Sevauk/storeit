import * as fs from 'fs'
import * as path from 'path'

let storeDir = './storeit'

export let makeFullPath = (filePath) => path.join(storeDir, filePath)

let fileCreate = (filePath) => {
  return new Promise((resolve, reject) => {
    fs.open(makeFullPath(filePath), 'w', (err, fd) => {
      if (!err) {
        resolve({
          path: filePath,
          fd
        })
      }
      else
        reject(err)
    })
  })
}

// let fileUpdate = (filePath) => {
//   let fullPath = makeFullPath(filePath)
//
// }

let fileDelete = (filePath) => {
  return new Promise((resolve, reject) => {
    fs.unlink(makeFullPath(filePath), (err) => {
      if (!err) resolve({path: filePath})
      else reject(err)
    })
  })
}

let fileMove = (src, dst) => {
  return new Promise((resolve, reject) => {
    fs.rename(makeFullPath(src), makeFullPath(dst), (err) => {
      if (!err) resolve({src, dst})
      else reject(err)
    })
  })
}

export default {
  setStoreDir(dirPath) {
    storeDir = dirPath
  },
  getStoreDir() {
    return storeDir
  },
  create: fileCreate,
  // update: fileUpdate,
  del: fileDelete,
  move: fileMove
}

// let makeInfo = (path, kind) => {
//   return {
//     path,
//     metadata: 'uninplemented for now',
//     contentHash: 'hache',
//     kind,
//     files: []
//   }
// }
//
// let dirToJson = (filename) => {
//
//   let stats = fs.lstatSync(filename)
//
//   let info = makeInfo(filename, stats.isDirectory ? 0 : 1)
//
//   if (stats.isDirectory()) {
//     info.files = fs.readdirSync(filename).map((child) => {
//       return dirToJson(filename + '/' + child)
//     })
//   }
//
//   return info
// }
//
// let mkdirUser = () => {
//   fs.mkdir(storeDir, (err) => {
//     if (err) {
//       logger.warn('cannot mkdir user dir')
//     }
//   })
// }
//
// let makeUserTree = () => {
//   mkdirUser()
//   let dir = dirToJson(storeDir)
//   dir.path = '/'
//   return dir
// }
