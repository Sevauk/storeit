import Promise from 'bluebird'
global.Promise = Promise

import commander from 'commander'
import dotenv from 'dotenv'
import fs from 'fs'
dotenv.config()

import Client from './client'
import {logger} from '../lib/log'

commander.version('0.0.1')
  .option('-d, --store <name>', 'set the user synced directory (default is ./storeit')
  .option('-s, --server <ip:port>', 'set the server address and port')
  .option('--developer <N>', 'set the token developerN where N is the developer id for testing')
  .parse(process.argv)

if (!commander.store)
  commander.store = 'storeit/'

try {
  fs.mkdirSync(commander.store)
}
catch (e) {
  if (e.code != 'EEXIST') {
    logger.error(e)
    process.exit(1)
  }
}

const cmd = commander
export default cmd

let client = new Client()

if (!commander.developer)
  commander.developer = ''
  
client.connect()
  .then(() => client.auth(`developer${commander.developer}`))
