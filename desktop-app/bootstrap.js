/*
 eslint-disable import/no-commonjs
*/
const program = require('commander')
global.Promise = require('bluebird')

program
  .version('0.0.1')
  .option('-s, --store <name>', 'set the user synced directory (default is ~/storeit')
  .option('-g, --gui', 'display gui')
  .option('-d, --dev', 'run in development mode')
  .parse(process.argv)

let mainPath = program.debug ? './src' : './build'

if (program.gui) {
  if (program.debug) require('coffee-script/register')
  mainPath += '/electron'
}
else {
  if (program.debug) require('babel-register')
  mainPath += '/cli'
}

const {run} = require(`${mainPath}-main`)
run(program)
