import fs from 'fs'
import logger from '../../lib/log'

export let settings = undefined

fs.read('server.conf', (err, res) => {
  if (err) {
    logger.error(`error when reading configuration file (${err})`)
    return
  }

  settings = JSON.parse(res)
})
