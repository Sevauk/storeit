const bluebird = require('bluebird')
const fs = bluebird.promisifyAll(require('fs-extra'))
const path = require('path')
const client = require('./client.js')
const repeat = require('repeat')

const syncTimeout = 10 // seconds
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
    if (fileAContent === sourceBContent)
      return false
  }
  catch (e) {
  }
  return true
}

const testFileExists = (cliId, filePath, source) => {

  console.log(`waiting for ${filePath} existence in client ${cliId} for each instance`)

  const cliList = client.get(cliId)

  for (const cli of cliList) {
    if (isDiff(source, cli.fullPath(filePath)))
      return undefined
  }

  return true
}


const checkInSync = (testFunc) =>
  repeat(testFunc)
    .every(tryTime, 's')
    .for(syncTimeout, 's')
    .start()
    .then(() => true, (err) => Promise.reject(err))

const asset = (name) => path.normalize(`${__dirname}/../assets/${name}`)
const cliGetHelper = (cliId) => {
  const cliList = client.get(cliId)
  if (cliList.length === 0) console.log(`no instance of client ${cliId}`)
  return cliList
}

const add = (cliId, assetName, targetPath) => {

  const cliList = cliGetHelper(cliId)
  // TODO: loop
  const cli = cliList[0]

  const targetFullPath = cli.fullPath(targetPath)

  return fs.copyAsync(asset(assetName), targetFullPath)
    .then(() =>
      checkInSync(() => testFileExists(cliId, targetPath, asset(assetName))))
}

const move = (cliId, srcPath, targetPath) =>{
  const cliList = cliGetHelper(cliId)
  const cli = cliList[0] // TODO: loop
  const srcFullPath = cli.fullPath(srcPath)
  const targetFullPath = cli.fullPath(targetPath)
  return fs.moveAsync(srcFullPath, targetFullPath)
    .then(() => checkInSync(() => testFileExists(cliId, targetPath, srcPath)))
//    .then(() => checkInSync(() => testFileInexists(cliId, targetPath, srcPath)))
}

module.exports = {
  add
}
