import commander from 'commander'
import dotenv from 'dotenv'
dotenv.config()

import Client from './client'
import * as userfile from './user-file'

commander
  .version('0.0.1')
  .option('-d, --store <name>', 'set the user synced directory (default is ./storeit')
  .parse(process.argv)

if (commander.store) {
  userfile.storeDir = commander.store
}
else {
  userfile.storeDir = './storeit'
}

let client = new Client()
client.auth('google')
  .then(() => console.log('joined server'))
