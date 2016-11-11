import commander from 'commander'
import * as ws from './ws.js'
import * as path from 'path'
import {logger} from './lib/log.js'
import fs from 'fs'
import {settings} from './settings.js'

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
  logger.logToFile(commander.logfile)

defaultParam('port', '7641')
defaultParam('addr', '0.0.0.0')
defaultParam('usrdir', 'storeit-users')

if (settings('STORMPATH_CLIENT_APIKEY_ID') === '')
  logger.warn('Setup server.conf if you want to support StoreIt login')

commander.usrdir += path.sep

fs.mkdir(commander.usrdir, () => 'ignore')

const cmd = commander
export default cmd

ws.listen()
