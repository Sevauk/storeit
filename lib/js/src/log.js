import * as path from 'path'

import winston from 'winston'

const PROJECT_ROOT = path.join(__dirname, '..')

const consoleTransport = new winston.transports.Console({
  level: 'debug',
  json: false,
  timestamp: false,
  colorize: 'all',
})

const defaultTransport = consoleTransport

const log = new winston.Logger({
  transports: [defaultTransport],
  exitOnError: false
})

export const logToFile = (filename) => {
  log.add(winston.transports.File, {
    filename,
    timestamp: () => new Date().toString(),
    json: false
  })
  log.remove(winston.transports.Console)
}

/**
 * Parses and returns info about the call stack at the given index.
 */
const getStackInfo = (stackIndex) => {
  // get call stack, and analyze it
  // get all file, method, and line numbers
  let stacklist = (new Error()).stack.split('\n').slice(3)

  // stack trace format:
  // http://code.google.com/p/v8/wiki/JavaScriptStackTraceApi
  // do not remove the regex expresses to outside of this method (due to a BUG in node.js)
  let stackReg = /at\s+(.*)\s+\((.*):(\d*):(\d*)\)/gi
  let stackReg2 = /at\s+()(.*):(\d*):(\d*)/gi

  let s = stacklist[stackIndex] || stacklist[0]
  let sp = stackReg.exec(s) || stackReg2.exec(s)

  if (sp && sp.length === 5) {
    return {
      method: sp[1],
      relativePath: path.relative(PROJECT_ROOT, sp[2]),
      line: sp[3],
      pos: sp[4],
      file: path.basename(sp[2]),
      stack: stacklist.join('\n')
    }
  }
}

/**
 * Attempts to add file and line number info to the given log arguments.
 */
const formatLogArguments = (args) => {
  args = Array.prototype.slice.call(args)

  let stackInfo = getStackInfo(1)

  if (stackInfo) {
    // get file path relative to project root
    let calleeStr = '(' + stackInfo.relativePath + ':' + stackInfo.line + ')'

    if (typeof args[0] === 'string') {
      args[0] = calleeStr + ' ' + args[0]
    }
    else {
      args.unshift(calleeStr)
    }
  }

  return args
}

// A custom logger interface that wraps winston, making it easy to instrument
// code and still possible to replace winston in the future.

export const logger = {
  debug(...args) {
    log.debug(...formatLogArguments(args))
  },
  info(...args) {
    log.info(...formatLogArguments(args))
  },
  warn(...args) {
    log.warn(...formatLogArguments(args))
  },
  error(...args) {
    log.error(...formatLogArguments(args))
  },
  toJson(obj) {
    return JSON.stringify(obj, null, 2)
  },
  setLevel(level='debug') {
    if (log.transports.console != null)
      log.transports.console.level = level
    else {
      log.transports.file.level = level
    }
  }
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

export default logger
