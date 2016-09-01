import winston from 'winston'

const consoleTransport = new winston.transports.Console({
      level: 'debug',
      json: false,
      timestamp: false,
      colorize: 'all',
})

let defaultTransport = consoleTransport

export const logger = new winston.Logger({
  transports: [defaultTransport],
  exitOnError: false
})

export const logToFile = (filename) => {

  logger.add(winston.transports.File, {filename, timestamp: () => new Date().toString(), json: false})
  logger.remove(winston.transports.Console)
}

export const ifnerr = (err, errMsg, successMsg, resolve) => {
  if (err) {
    logger.error(`${errMsg} ${err}`)
  }
  else {
    if (successMsg) {
      logger.info(successMsg)
    }
    if (resolve) {
      resolve()
    }
  }
}
