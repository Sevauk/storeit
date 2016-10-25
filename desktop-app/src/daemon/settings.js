import * as path from 'path'

import storage from 'node-persist'

import logger from '../../lib/log'

const storeItData = 'user-settings'

let USER_HOME = process.env[
  process.platform === 'win32' ? 'USERPROFILE' : 'HOME'
]
if (process.env.NODE_ENV === 'test') USER_HOME = process.env.TMP || '/tmp'

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

const clone = (obj) => JSON.parse(JSON.stringify(obj))

const load = () => {
  let loaded = storage.getItemSync(storeItData)
  logger.debug(`[SETTINGS] ${logger.toJson(loaded)}`)
  return loaded
}

const loadDefaults = () => clone(defaults)

let settings = {}

const set = (params) => {
  settings.auth = params.auth
  settings.folderPath = params.folderPath
  settings.space = params.space
  settings.bandwidth = params.bandwidth
}

set(load() || loadDefaults())

const save = () => {
  storage.setItemSync(storeItData, clone(settings))
}

const reload = () => {
  let saved = load()
  set(saved)
}

const clear = (skipSave=false) => {
  set(loadDefaults())
  if (!skipSave) save()
}

const reset = () => {
  const auth = settings.auth
  clear(true)
  settings.auth = auth
  save()
}

const get = (key) => {
  if (key != null) {
    return settings[key]
  }
  return settings
}

const getAuthType = () => settings.auth.type

const getTokens = type =>
  type === settings.auth.type ? settings.auth.tokens : null

const setTokens = (type, tokens) => {
  settings.auth.type = type
  settings.auth.tokens = tokens
}

const resetTokens = () => setTokens(null, null)

const getStoreDir = () => settings.folderPath

const setStoreDir = folderPath => {
  settings.folderPath = path.resolve(folderPath)
}

const getHostDir = () => path.join(settings.folderPath, '.storeit')

const getAllocated = () => settings.space

const setAllocated = (allocatedSpace) => {
  settings.space = allocatedSpace
}

const getBandwidth = () => settings.bandwidth

const setBandwidth = max => {
  settings.bandwidth = max
}

export default {
  USER_HOME,
  defaults,
  get,
  getAuthType,
  setTokens,
  getTokens,
  resetTokens,
  setStoreDir,
  getStoreDir,
  getHostDir,
  getAllocated,
  setAllocated,
  getBandwidth,
  setBandwidth,
  save,
  reset,
  clear,
  reload
}
