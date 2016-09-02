import Client from './daemon/client'
import {logger} from '../lib/log'

export const run = (program) => {
  let client = new Client()
  client.connect()
    .then(() => client.auth('developer', program.developer))
    .catch(() => logger.error('something happened'))
}
