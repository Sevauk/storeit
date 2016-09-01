import Client from './daemon/client'
import logger from '../lib/log'

export const run = () => {
  let client = new Client()

  client.connect()
    .then(() => client.auth('developer'))
    .catch(err => logger.error('An unexpected error occured:', err))
}
