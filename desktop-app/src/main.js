import Promise from 'bluebird'
global.Promise = Promise

import commander from 'commander'
import dotenv from 'dotenv'
dotenv.config()

import Client from './client'
import userFile from './user-file'
import {logger} from '../lib/log'

commander
  .version('0.0.1')
  .option('-d, --store <name>', 'set the user synced directory (default is ./storeit')
  .parse(process.argv)

if (commander.store) userFile.setStoreDir(commander.store)

let client = new Client()

let ready = () =>  {
  logger.info('joined server')
  client.recvFADD({
    'files': [
      {
        'path': '/foo',
        'metadata': {},
        'IPFSHash': 'QmPQyNsGgU48KXkAv2xLWHwHMSK3nHk6EAbeex7kYVeE69',
        'isDir': false,
        'files': []
      }
    ]
  })
}

client.auth('google').then(ready)

  // process.env.IPFS_PORT = 5001
  // const filePath = 'foo'
  // const hash = 'QmPQyNsGgU48KXkAv2xLWHwHMSK3nHk6EAbeex7kYVeE69'
  //
  // let node = new IPFSnode()
  // node.get(hash, filePath)
  //   .then((buf) => console.log(buf))
