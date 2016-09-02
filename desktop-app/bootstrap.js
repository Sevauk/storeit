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

let mainPath = program.dev ? './src' : './build'

if (program.logfile) log.logToFile(program.logfile)

if (program.gui) {
  if (program.dev) require('coffee-script/register')
  mainPath += '/electron'
}
else {
  if (program.dev) require('babel-register')
  mainPath += '/cli'
}

const {run} = require(`${mainPath}-main`)
run(program)
