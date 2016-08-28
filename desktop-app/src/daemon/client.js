import * as fs from 'fs'

import WebSocket from 'ws'

import {FacebookService, GoogleService} from './oauth'
import userFile from './user-file.js'
import {logger} from '../../lib/log'
import Watcher from './watcher'
import {Command, Response} from '../../lib/protocol-objects'
import store from './store.js'
import tree from './tree.js'
import IPFSnode from './ipfs'
import settings from './settings'

WebSocket = Promise.promisifyAll(WebSocket)

const MAX_RECO_TIME = 4

export default class Client {

  constructor() {
    this.recoTime = 1
    this.responseHandlers = {} // custom server response handlers
    this.ipfs = new IPFSnode()
    this.fsWatcher = new Watcher(settings.getStoreDir())
    this.fsWatcher.setEventHandler((ev) => this.handleFsEvent(ev))
  }

  auth(type, opener) {
    let service
    switch (type) {
      case 'fb':
      break
        service = new FacebookService()
      case 'gg':
        service = new GoogleService()
        break
      case 'developer':
        return this.developer()
      default:
        return this.login()
    }

    return service.oauth(opener)
      .then((tokens) => this.join(type, tokens.access_token))
    )
  }

  developer() {
    return this.join('gg', 'developer')
  }

  login() {
    throw new Error('StoreIt auth not implemented yet') // TODO
  }

  connect() {
    const {SERVER_ADDR, SERVER_PORT} = process.env
    this.sock = new WebSocket(`ws://${SERVER_ADDR}:${SERVER_PORT}`)
    logger.debug('[SOCK] attempting connection')

    this.sock.on('close', () => this.reconnect())
    this.sock.on('error', () => logger.error('[SOCK] socket error occured'))
    this.sock.on('message', (data) => this.manageResponses(JSON.parse(data)))

    return new Promise((resolve) => this.sock.on('open', resolve))
      .then(() => this.recoTime = 1)
      .tap(() => logger.info('[SOCK] connection established'))
  }

  reconnect() {
    logger.error(`[SOCK] attempting to reconnect in ${this.recoTime} seconds`)
    let done = Promise.delay(this.recoTime * 1000).then(() => this.connect())

    if (this.recoTime < MAX_RECO_TIME) ++this.recoTime
    return done
  }

  manageResponses(res) {
    let handler = this.responseHandlers[res.commandUid]
    if (handler != null) delete this.responseHandlers[res.commandUid]
    else handler = this[`recv${res.command}`] // set to default handler

    if (handler != null) handler.call(this, res)
    else logger.error(`[PROTO] unhandled response: ${JSON.stringify(res)}`)
  }

  waitResponse(req) {
    let msg = `[PROTO] request' ${JSON.stringify(req)} `

    return new Promise((resolve, reject) =>
      this.responseHandlers[req.uid] = (res) =>
        res.code === 0 ? : resolve(res) : reject(new Error(`${msg} failed`))
    )
      .then((res) => res.params)
      .tap(() => logger.info(`${msg} succeeded`))
  }

  response(uid, msg='', code=0) {
    return this.send(new Response(code, msg, uid))
  }

  sendSuccess(uid, msg='') {
    return this.response(uid, msg, 0)
  }

  sendError(uid, msg='error', code=1) {
    return this.response(uid, msg, code)
  }

  request(req, params) {
    let data = new Command(req, params)
    return this.send(data)
      .then(() => this.waitResponse(data))
  }

  send(data) {
    logger.info(`[PROTO] sending data ${JSON.stringify(data)}`)
    return this.sock.sendAsync(JSON.stringify(data))
  }

  join(authType, accessToken) {
    return store.getHostedChunks()
      .then((hashes) => {authType, accessToken, hosting: hashes})
      .then((data) => this.sendReq('JOIN', data))
      .then((params) => this.recvFADD({files: [params.home]})
      .then(() => logger.info('[PROTO] home loaded'))
      .catch((err) => logger.error(err))
  }

  recvFADD(params, log=true) {
    if (log) logger.info(`received FADD => ${JSON.stringify(params)}`)

    if (!params.files) {
      return Promise.resolve()
    }

    if (!Array.isArray(params.files)) {
      params.files = Object.keys(params.files).map((key) => params.files[key])
    }

    let status = []
    let res

    for (let file of params.files) {

      userFile.ignore(file.path)

      const realPath = userFile.fullPath(file.path)

      if (file.isDir) {
        res = userFile.dirCreate(file.path)
          .then(() => this.recvFADD({files: file.files}, false))
      }
      else {

        fs.stat(realPath, (err) => {

          const getFile = () => {
            userFile.create(file.path, '') // TODO: show user that we are syncing
            logger.info(`downloading file ${file.path} from ipfs`)
            res = this.ipfs.get(file.IPFSHash)
              .then((buf) => {
                logger.info(`download of ${file.path} is over`)
                return userFile.create(file.path, buf)
              })
              .then(() => userFile.unignore(file.path))
              .catch(() => userFile.unignore(file.path))
              .delay(500)  // QUCIK FIX, FIMXE
              .then(() => this.ipfs.add(file.path))
              .catch((err) => logger.error(err))
          }

          const exists = !err

          if (exists) {
            this.ipfs.add(file.path)
              .then((hash) => {
                if (hash[0].Hash === file.IPFSHash) {
                  userFile.unignore(file.path)
                  return
                }
                getFile()
              })
              .catch((err) => logger.error(err))
          }
          else getFile()
        })
      }
      status.push(res)
    }
    return Promise.all(status)
  }

  recvRESP(params, command) {
    logger.info(`received ${command.code === 0 ? 'successful' : `failure ${command.code}`} response`)
  }

  recvFUPT(params) {
    logger.info(`received FUPT => ${JSON.stringify(params)}`)
    return this.recvFADD(params, false)
  }

  recvFDEL(params) {
    logger.info(`received FDEL => ${JSON.stringify(params)}`)
    return Promise.map(params.files, (file) => userFile.del(file))
      .each((file) => logger.info(`removed file ${file.path}`))
  }

  recvFMOV(params) {
    logger.info(`received FMOV => ${JSON.stringify(params)}`)
    return userFile.move(params.src, params.dest)
      .then((file) => logger.info(`moved file ${file.src} to ${file.dst}`))
  }

  recvFSTR(params) {
    logger.info(`received FSTR => ${JSON.stringify(params)}`)
    return store.FSTR(this.ipfs, params.hash, params.keep)
      .then(() => this.success())
      .catch((err) => logger.error('FSTR: ' + err))
  }

  sendFADD(filePath) {
    return tree.createTree(filePath, this.ipfs)
      .then((file) => this.sendReq('FADD', {files: [file]}))
      .catch((err) => logger.error('FADD: ' + err))
  }

  sendFUPT(filePath) {
    return tree.createTree(filePath, this.ipfs)
      .then((file) => this.sendReq('FUPT', {files: [file]}))
      .catch((err) => logger.error('FUPT: ' + err.text))
  }

  sendFDEL(filePath) {
    return this.sendReq('FDEL', {files: [userFile.toStoreitPath(filePath)]})
      .catch((err) => logger.error('FDEL: ' + err.text))
  }

  sendFMOV(src, dst) {
    return this.sendReq('FMOV', {src, dst})
      .catch((err) => logger.error('FMOV: ' + err.text))
  }

  handleFsEvent(ev) {
    let handler = this[`send${ev.type}`]
    if (handler) {
      handler.call(this, ev.path)
        .catch((err) => logger.debug(err))

      // TODO: manage FMOV
    }
    else logger.warn(`[FileWatcher] unhandled event ${ev}`)
  }

  reloadSettings() {
    // TODO
    settings.reload()
  }
}
