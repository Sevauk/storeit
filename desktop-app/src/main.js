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

if (commander.store) {
  userFile.setStoreDir(commander.store)
}
else {
  userFile.setStoreDir('./storeit')
}

let client = new Client()
client.auth('google')
  .then(() => logger.info('joined server'))
