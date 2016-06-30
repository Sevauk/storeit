let uid = 0

export const Error = {
  BADCREDENTIALS: {code: 1, msg: 'Invalid credentials'},
  BADSCOPE: {code: 2, msg: 'Bad OAuth scope'},
  UNKNOWNAUTHTYPE: {code: 3, msg: 'Unknown authentication method'},
  SERVERERROR: {code: 4, msg: 'The server failed'},
}

export class Command {

  constructor(name, parameters) {
    this.uid = uid++
    this.command = name
    this.parameters = parameters
  }
}

export class Response {
  constructor(code, text, uid, parameters) {
    this.code = code,
    this.text = text,
    this.commandUid = uid,
    this.parameters = parameters
    this.command = "RESP"
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
