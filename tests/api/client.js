const path = require('path')
const bluebird = require('bluebird')
const fs = bluebird.promisifyAll(require('fs-extra'))
const spawn = require('child_process').spawn
const repeat = require('./repeat.js')

const codeLocation = path.normalize(`${__dirname}/../../`)
const desktopClientPath = codeLocation + path.normalize('desktop-app/')
const storeit_test_dir= '/tmp/storeit_test'
const clients = {}

let instanceCounter = 0

try {
  fs.removeSync(storeit_test_dir)
  fs.mkdirSync(storeit_test_dir)
  fs.mkdirSync('logs', () => null)
}
catch (e) {
}

const runIn = (dir, cb) => {

  const current = __dirname
  process.chdir(dir)
  const cbRet = cb()
  process.chdir(current)
  return cbRet
}

const runIPFS = () => spawn('ipfs', ['daemon'])

class Client {

  constructor(id) {

    runIPFS()

    this.id = id
    this.homeDirName = `storeit-cli-${id}_${instanceCounter++}`
    this.home = `${storeit_test_dir}/${this.homeDirName}`

    return runIn(desktopClientPath, () => {

      const cli = spawn('node', `-r dotenv/config bootstrap.js --store ${this.home} -d --developer ${id}`.split(' '))
      const cliLog = path.normalize(`../logs/cli${id}_${instanceCounter}`)

      const logErr = (err) => {
        if (err)
        console.log(err)
      }

      cli.stderr.on('data', (data) =>
      fs.appendFile(`${cliLog}_stderr.log`, data, (err) => logErr(err)))
      cli.stdout.on('data', (data) =>
      fs.appendFile(`${cliLog}_stdout.log`, data, (err) => logErr(err)))

      this.process = cli
      clients[instanceCounter] = this

      return this.clientWillStart()
    })
  }

  // the client is obviously running when some file appears
  clientWillStart() {
    return repeat.every(1, 20, // every 1s for max 20s
      () => fs.lstatAsync(`${this.home}/readme.txt`)) // then this until it resolves
  }

  fullPath(p) {
    return path.normalize(`${this.home}/${p}`)
  }
}

const runClient = (devId) => new Client(devId)
const getClient = (id) => {

  let instances = []

  for (const key of Object.keys(clients)) {
    if (clients[key].id === id)
    instances.push(clients[key])
  }

  return instances
}

const kill = (cliId, cliInstance) => {

  Object.keys(clients).forEach((key) => {
    if (clients[key].id === cliId || cliId === undefined) {
      fs.removeSync(clients[key].home) // sorry async todo
      clients[key].process.kill()
      delete clients[key]
    }
  })

  return Promise.resolve()
}

module.exports = {
  run: runClient,
  get: getClient,
  kill,
}
