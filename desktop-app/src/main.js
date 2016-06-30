import commander from 'commander'
import * as userfile from './user-file.js'
import * as ws from './ws.js'
import * as auth from './auth.js'

commander
  .version('0.0.1')
  .option('-d, --store <name>', 'set the user synced directory (default is ./storeit')
  .option('-c, --code <code>', 'set the google auth code')
  .parse(process.argv)

if (commander.store) {
  userfile.storeDir = commander.store
}
else {
  userfile.storeDir = './storeit'
}

//ws.co('test')

import * as ipfs from './ipfs.js'

/*
if (commander.code) {
  auth.getGoogleToken(commander.code, (tokens) => {
    ws.co(tokens.access_token)
  })
}
else {
  auth.googleAuth()
}
*/
