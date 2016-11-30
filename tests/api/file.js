const bluebird = require('bluebird')
const fs = bluebird.promisifyAll(require('fs-extra'))
const path = require('path')
const client = require('./client.js')
const repeat = require('./repeat.js')

const syncTimeout = 200 // seconds
const tryTime = 1 // seconds

const isDiff = (fileA, fileB) => {
  try {
    const statA = fs.lstatSync(fileA)
    const statB = fs.lstatSync(fileB)
    if (statA.isDirectory() && statB.isDirectory())
      return false
    if (statA.isDirectory() || statB.isDirectory())
      return true
    const fileAContent = fs.readFileSync(fileA)
    const fileBContent = fs.readFileSync(fileB)
    if (fileAContent.equals(fileBContent)) {
      return false
    }
  }
  catch (e) {
  }
  return true
}

const testFileExists = (cliId, filePath, asset) => {

  const cliList = client.get(cliId)

  for (const cli of cliList) {
    if (isDiff(asset, cli.fullPath(filePath))) {
      return Promise.reject()
    }
  }

  return Promise.resolve()
}


const checkInSync = (cliId, testFunc, param) => {

  const testEveryInstance = () => {

    const cliList = client.get(cliId)

    for (const cli of cliList) {
      if (testFunc(cli.home, param))
        return Promise.reject()
    }
    return Promise.resolve()
  }

  return repeat.every(tryTime, syncTimeout, testEveryInstance)
}


const asset = (name) => path.normalize(`${__dirname}/../assets/${name}`)
const cliGetHelper = (cliId) => {
  const cliList = client.get(cliId)
  if (cliList.length === 0) console.error(`no instance of client ${cliId}`)
  return cliList
}

const add = (cliId, assetName, targetPath) => {

  const cliList = cliGetHelper(cliId)
  // TODO: loop
  const cli = cliList[0]

  if (!cli) return Promise.reject(new Error(`trying to add but no client #${cliId} running. ${cliList}`))

  const targetFullPath = cli.fullPath(targetPath)

  return fs.copyAsync(asset(assetName), targetFullPath)
    .then(() =>
      checkInSync(() => testFileExists(cliId, targetPath, asset(assetName))))
}

const move = (cliId, assetPath, targetPath) =>{
  const cliList = cliGetHelper(cliId)
  const cli = cliList[0] // TODO: loop
  const srcFullPath = cli.fullPath(srcPath)
  const targetFullPath = cli.fullPath(targetPath)
  return fs.moveAsync(srcFullPath, targetFullPath)
    .then(() => fileExists(cliId, targetPath, assetPath))
//    .then(() => checkInSync(() => testFileInexists(cliId, targetPath, srcPath)))
}

const fileExists = (cliId, targetPath, asset) =>
  checkInSync(() => testFileExists(cliId, targetPath, asset))

const dirIsNotEmpty = (home) => fs.readdirSync(home).length > 1 // readme.txt doesn't count

const emptyDir = (cliId, path) =>
  fs.emptyDirAsync(path)
    .then(() => fs.writeFileAsync(path + '/readme.txt', 'readme')) // I need it to detect that a client runs. TODO: will not work on windows
    .then(() => checkInSync(cliId, dirIsNotEmpty))

const remove = (cliId, what) => {
  if (what === '*') {
    const cli = client.get(cliId)[0]
    return emptyDir(cliId, cli.home)
  }
}

module.exports = {
  add,
  remove,
  exists: fileExists,
  asset
}
