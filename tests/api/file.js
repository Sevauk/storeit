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


const checkInSync = (testFunc) => repeat.every(tryTime, syncTimeout, testFunc)

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
    .then(() => FileExists(cliId, targetPath, assetPath))
//    .then(() => checkInSync(() => testFileInexists(cliId, targetPath, srcPath)))
}

const fileExists = (cliId, targetPath, asset) =>
  checkInSync(() => testFileExists(cliId, targetPath, asset))

module.exports = {
  add,
  exists: fileExists,
  asset
}
