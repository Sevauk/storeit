import commander from 'commander'
import * as ws from './ws.js'
import * as path from 'path'
import * as log from './lib/log.js'
import fs from 'fs'
import * as stormpath from './stormpath.js'

commander.version('0.0.1')
  .option('-p, --port <port>', 'set the port to listen to')
  .option('-a, --addr <ip>', 'set the address to listen on')
  .option('-u, --usrdir <dir>', 'set the directory in which store the users data')
  .option('-l, --logfile <filename>', 'log to a file instead of the console')
  .parse(process.argv)


const defaultParam = (field, deflt) => {
  if (!commander[field])
    commander[field] = deflt
}

if (commander.logfile)
  log.logToFile(commander.logfile)

defaultParam('port', '7641')
defaultParam('addr', '0.0.0.0')
defaultParam('usrdir', 'storeit-users')

commander.usrdir += path.sep

try {
  fs.mkdirSync(commander.usrdir)
}
catch(e) {
  log.logger.debug('userdir already there')
}

const cmd = commander
export default cmd

ws.listen()
