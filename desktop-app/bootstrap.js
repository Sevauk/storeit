/*
 eslint-disable import/no-commonjs
*/
global.Promise = require('bluebird')

const
  program = require('commander'),
  log = require('./lib/log')

program
  .version('0.0.1')
  .option('-s, --store <name>', 'set the user synced directory (default is ~/storeit')
  .option('-g, --gui', 'display gui')
  .option('-d, --dev', 'run in development mode')
  .option('--developer <N>', 'set the token developerN where N is the developer id for testing')
  .option('-l, --logfile <filename>', 'log to a file instead of the console')
  .parse(process.argv)

let srcPath

if (program.logfile) log.logToFile(program.logfile)

if (program.dev) {
  log.setLevel('debug')
  srcPath = './src'
  require(program.gui ? 'coffee-script/register' : 'babel-register')
}
else {
  log.setLevel('info')
  srcPath = './build'
}

const mainPath = srcPath + '/' + (program.gui ? 'electron' : 'cli')

const settings = require(`${srcPath}/daemon/settings`).default
settings.reset() // TODO
settings.fromArgs(program)

const {run} = require(`${mainPath}-main`)
run(program)
