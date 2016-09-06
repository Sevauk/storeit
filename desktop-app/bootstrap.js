/*
 eslint-disable import/no-commonjs
*/
global.Promise = require('bluebird')

const
  program = require('commander'),
  log = require('./lib/log').default,
  settings = require('./build/daemon/settings').default

program
  .version('0.0.1')
  .option('-s, --store <name>', 'set the user synced directory (default is ~/storeit')
  .option('-g, --gui', 'display gui')
  .option('-d, --dev', 'run in development mode')
  .option('--developer <N>', 'set the token developerN where N is the developer id for testing')
  .option('-l, --logfile <filename>', 'log to a file instead of the console')
  .parse(process.argv)

if (program.logfile) log.logToFile(program.logfile)

if (program.dev) {
  log.setLevel('debug')
}
else {
  log.setLevel('info')
}

const main = program.gui ? 'electron' : 'cli'

settings.reset() // TODO
if (program.store) settings.setStoreDir(program.store)

const {run} = require(`./build/${main}-main`)
run(program)
