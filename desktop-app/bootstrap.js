/*
 eslint-disable import/no-commonjs
*/
const program = require('commander')
const logger = require('./lib/log').default
global.Promise = require('bluebird')

program
  .version('0.0.1')
  .option('-s, --store <name>', 'set the user synced directory (default is ~/storeit')
  .option('-g, --gui', 'display gui')
  .option('-d, --dev', 'run in development mode')
  .parse(process.argv)

let srcPath

if (program.dev) {
  logger.setLevel('debug')
  srcPath = './src'
  require(program.gui ? 'coffee-script/register' : 'babel-register')
}
else {
  logger.setLevel('info')
  srcPath = './build'
}

const mainPath = srcPath + '/' + (program.gui ? 'electron' : 'cli')

const settings = require(`${srcPath}/daemon/settings`).default
settings.reset() // TODO
settings.fromArgs(program)

const {run} = require(`${mainPath}-main`)
run(program)
