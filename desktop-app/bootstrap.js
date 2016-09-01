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

let mainPath = program.dev ? './src' : './build'

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
