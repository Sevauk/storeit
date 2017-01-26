const readline = require('readline')
import {logger} from './lib/log.js'
import fs from 'fs-extra'
import cmd from './main.js'
import * as user from './user.js'

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
})

const use_command = (argv) => {
  if (argv[0] == 'clean') {
    fs.remove(cmd.usrdir, () => {
      fs.mkdir(cmd.usrdir, () => 'ignore')
      for (const email of Object.keys(user.users)) {
        for (const cid of Object.keys(user.users[email].sockets)) {
          user.disconnectSocket(user.users[email].sockets[cid])
        }
      }
      logger.info('User content has been reset, Everyone has been disconnected')
    })
  } else if (argv[0] == 'stat') {
    logger.info(`${Object.keys(user.users).length} connected users`)
  } else {
    logger.error('Unknown command ' + argv[0])
  }
}

const listen = () =>
  rl.question('', (answer) => {
      use_command(answer.split(' '))
      listen()
  })

listen()
