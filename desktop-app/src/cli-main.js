import Client from './daemon/client'
import log from '../lib/log'

export const run = (program) => {
  let client = new Client()

  client.connect('developer', program.developer)
  // client.start()
  //   .then(() => client.auth('developer', program.developer))
    .catch(err => log.error('An unexpected error occured:', err))
}
