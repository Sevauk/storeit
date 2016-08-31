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

let srcPath = program.dev ? './src' : './build'

let mainPath

if (program.gui) {
  if (program.dev) require('coffee-script/register')
  mainPath = `${srcPath}/electron`
}
else {
  if (program.dev) require('babel-register')
  mainPath = `${srcPath}/cli`
}

const settings = require(`${srcPath}/daemon/settings`).default
settings.reset()
settings.fromArgs(program)

const {run} = require(`${mainPath}-main`)
run(program)
