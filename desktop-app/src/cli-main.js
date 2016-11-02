import Client from './daemon/client'
import log from '../lib/log'

export const run = (program) => {
  let client = new Client()

  client.start({type: 'developer', devId: program.developer})
    .then(() => log.info('[STATUS] Client is ready'))
    .catch(err => log.error('An unexpected error occured:', err))
}
