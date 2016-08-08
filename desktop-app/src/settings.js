import * as path from 'path'

import storage from 'node-persist'

import {logger} from '../lib/log'

const storeItData = 'user-settings'
const USER_HOME = process.env[
  process.platform === 'win32' ? 'USERPROFILE' : 'HOME'
]

storage.initSync({
  dir: path.join(USER_HOME, '.storeitrc')
})

const defaults = {
  auth: {
    type: null,
    tokens: null
  },
  folderPath: path.join(USER_HOME, 'storeit'),
  space: 2048,
  bandwidth: 0
}

let settings = storage.getItemSync(storeItData) || defaults

logger.info('[Settings]: status ', settings)

const get = (key) => {
  if (key != null) {
    logger.debug('getting from localstorage', settings[key])
    return settings[key]
  }
  return settings
}

const save = () => {
  logger.debug('saving settings', settings)
  storage.setItem(storeItData, settings)
}

const reset = () => {
  settings = defaults
}


const getTokens = (type) =>
  type === settings.auth.type ? settings.auth.tokens : null

const setTokens = (type, tokens) => {
  settings.auth.type = type
  settings.auth.tokens = tokens
}

const resetTokens = () => setTokens(null, null)

const getFolderPath = () => settings.folderPath

const setFolderPath = (folderPath) => {
  settings.folderPath = folderPath
}

const getAllocated = () => settings.space

const setAllocated = (allocatedSpace) => {
  settings.space = allocatedSpace
}

const getBandwidth = () => settings.bandwidth

const setBandwidth = (max) => {
  settings.bandwidth = max
}

export default {
  get,
  setTokens,
  getTokens,
  resetTokens,
  setFolderPath,
  getFolderPath,
  getAllocated,
  setAllocated,
  getBandwidth,
  setBandwidth,
  save,
  reset
}
