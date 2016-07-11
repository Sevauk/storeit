let uid = 0

export const ApiError = {
  BADCREDENTIALS: {code: 1, msg: 'Invalid credentials'},
  BADSCOPE: {code: 2, msg: 'Bad OAuth scope'},
  UNKNOWNAUTHTYPE: {code: 3, msg: 'Unknown authentication method'},
  SERVERERROR: {code: 4, msg: 'The server failed'},
  BADTREE: {code: 5, msg: 'The tree does not match server reprensentation. Login again.'},
  BADREQUEST: {code: 6, msg: 'The request is invalid'}
}

export const errWithStack = (err) => {
  err.trace = new Error().stack
  return err
}

export class Command {

  constructor(name, parameters) {
    this.uid = uid++
    this.command = name
    this.parameters = parameters
  }
}

const debug = true

export class Response {
  constructor(code, text, uid, parameters, stack) {
    this.code = code
    this.text = text
    this.commandUid = uid
    this.parameters = parameters
    this.command = "RESP"
    if (debug) this.stack = stack
  }
}

export const makeFileObj = (path, IPFSHash, files) => {

  if (IPFSHash === undefined) {
    IPFSHash = null
  }
  if (files === undefined) {
    files = null
  }

  return {
    path,
    metadata: null,
    IPFSHash,
    isDir: IPFSHash == null,
    files,
  }
}
