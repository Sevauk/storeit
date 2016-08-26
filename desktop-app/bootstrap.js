/*
 eslint-disable import/no-commonjs
*/
const program = require('commander')

program
  .version('0.0.1')
  .option('-s, --store <name>', 'set the user synced directory (default is ~/storeit')
  .option('-g, --gui', 'display gui')
  .option('-d, --debug', 'use for debug environment')
  .parse(process.argv)

let mainPath = program.debug ? './src' : './build'

if (program.gui) {
  if (program.debug) require('coffee-script/register')
  mainPath += '/gui'
}
else {
  if (program.debug) require('babel-register')
  mainPath += '/cli'
}

const {run} = require(`${mainPath}-main`)
run(program)
