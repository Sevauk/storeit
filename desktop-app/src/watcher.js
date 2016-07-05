import * as fs from 'fs'
import * as usr from './user-file.js'
import * as tree from './tree.js'
import * as path from 'path'
import * as ws from './ws.js'
import * as api from './protocol-objects.js'
import * as ipfs from './ipfs.js'

export const watch = () => {

  fs.watch(usr.storeDir, {recursive: true}, (event, filename) => {

    const filenameFromRoot = path.sep + filename

    tree.setTree(usr.home, filenameFromRoot, (tree, fpath) => {

      if (tree === undefined) {
        return console.log('please reconnect to be in sync')
      }

      if (tree.files !== undefined && tree.files[fpath] === undefined) {

        ipfs.add(usr.storeDir + path.sep + filename, (err, data) => {

          if (err) {
            return console.log(err)
          }
          const cmd = new api.Command('FADD', {"files" : [api.makeFileObj(filenameFromRoot, data[0].Hash)]})
          ws.sendCmd(cmd)
        })
      }
      else {
        console.log("do FUPT")
      }
    })
  })

}
