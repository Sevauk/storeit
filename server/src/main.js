import commander from 'commander'
import * as ws from './ws.js'
import * as path from 'path'
import {logger} from './lib/log.js'
import fs from 'fs'

commander.version('0.0.1')
  .option('-p, --port <port>', 'set the port to listen to')
  .option('-a, --addr <ip>', 'set the address to listen on')
  .option('-u, --usrdir <dir>', 'set the directory in which store the users data')
  .parse(process.argv)


const defaultParam = (field, deflt) => {
  if (!commander[field])
    commander[field] = deflt
}

defaultParam('port', '7641')
defaultParam('addr', '0.0.0.0')
defaultParam('usrdir', 'storeit-users')

commander.usrdir += path.sep

try {
  fs.mkdirSync(commander.usrdir)
}
catch(e) {
  logger.debug('userdir already there')
}

const cmd = commander
export default cmd

ws.listen()
