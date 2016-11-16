const path = require('path')
const fs = require('fs')
const spawn = require('child_process').spawn

const codeLocation = path.normalize('../')
const desktopClientPath = codeLocation + path.normalize('desktop-app/')

fs.mkdir('logs', () => null)

const runIn = (dir, cb) => {

  const current = __dirname
  process.chdir(dir)
  cb()
  process.chdir(current)
}

const runIPFS = () => spawn('ipfs', ['daemon'])

const runClient = (devId) => {

  runIPFS()
  runIn(desktopClientPath, () =>
    cli = spawn('node', `-r dotenv/config bootstrap.js --store /tmp/storeit-cli-${devId} --developer ${devId}`.split(' ')))

  const cliLog = `logs/cli${devId}`

  const logErr = (err) => {
    if (err)
      console.log(err)
  }

  cli.stderr.on('data', (data) =>
    fs.appendFile(`${cliLog}_stderr.log`, data, (err) => logErr(err)))
  cli.stdout.on('data', (data) =>
    fs.appendFile(`${cliLog}_stdout.log`, data, (err) => logErr(err)))

  cli.on('close', (code) => console.log(`Program exited with code ${code}`))
  return Promise.resolve(cli)
}

module.exports = {
  runClient
}
