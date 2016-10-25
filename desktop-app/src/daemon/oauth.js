import open from 'open'
import express from 'express'
import gapi from 'googleapis'
import fbgraph from 'fbgraph'

import logger from '../../lib/log'
import settings from './settings'

Promise.promisifyAll(fbgraph)

const HTTP_PORT = 7777
const REDIRECT_URI = `http://localhost:${HTTP_PORT}/`

class OAuthProvider {
  constructor(type) {
    this.express = express()
    this.type = type
    this.tokens = settings.getTokens(type)
  }

  oauth(opener=open) {
    let url = this.generateAuthUrl()
    let authorized = Promise.resolve(url ? this.waitAuthorized() : true)
    if (url) opener(url)

    return authorized
      .then(code => this.getToken(code))
      .tap(tokens => this.setCredentials(tokens))
      .then(tokens => this.extendAccesToken(tokens))
      .tap(tokens => this.saveTokens(tokens))
  }

  waitAuthorized() {
    return new Promise((resolve) => {
      this.express.use('/', (req, res) => {
        if (this.http != null) resolve(this.getCode(req, res))
      })
      this.http = this.express.listen(HTTP_PORT)
      logger.debug(`[OAUTH] Http server listening on port ${HTTP_PORT}`)
    })
  }

  getCode(req, res) {
    let msg = 'Thank you for authenticating, you can now quit this page.'
    res.send(`StoreIt: ${msg}`)

    this.http.close()
    delete this.http
    logger.debug('[OAUTH] Access granted, Http server stopped')

    let code = req.query.code
    if (code == null) throw new Error('oauth: could not get code')
    return code
  }

  saveTokens(tokens) {
    this.tokens = tokens
    settings.setTokens(this.type, tokens)
    settings.save()
  }

  hasTokens() {
    return this.tokens != null
  }
}

export class GoogleService extends OAuthProvider {
  constructor() {
    super('google')

    const {GAPI_CLIENT_ID, GAPI_CLIENT_SECRET} = process.env

    this.client = new gapi.auth.OAuth2(GAPI_CLIENT_ID,
      GAPI_CLIENT_SECRET, REDIRECT_URI)

    this.client = Promise.promisifyAll(this.client)
    if (this.hasTokens()) this.client.setCredentials(this.tokens)
  }

  generateAuthUrl() {
    if (this.hasTokens()) return null

    return this.client.generateAuthUrl({
      scope: 'email',
      'access_type': 'offline'
    })
  }

  getToken(code) {
    if (code != null) {
      logger.info('[OAUTH:gg] exchanging code against access token')
      return this.client.getTokenAsync(code)
    }
    else {
      logger.info('[OAUTH:gg] refreshing token')
      return this.client.refreshAccessTokenAsync()
    }
  }

  setCredentials(tokens) {
    this.client.setCredentials(tokens)
  }

  extendAccesToken(tokens) {
    return tokens // TODO
  }
}

export class FacebookService extends OAuthProvider {
  constructor() {
    super('facebook')

    const {FBAPI_CLIENT_ID, FBAPI_CLIENT_SECRET} = process.env
    this.client = fbgraph
    this.credentials = {
      'client_id': FBAPI_CLIENT_ID,
      'redirect_uri': REDIRECT_URI,
      'client_secret': FBAPI_CLIENT_SECRET,
    }
    this.authUrl = this.client.getOauthUrl({
      'client_id': this.credentials['client_id'],
      'redirect_uri': REDIRECT_URI,
      'scope': 'email'
    })
  }

  generateAuthUrl() {
    const ENDPOINT = 'auth/fb'
    this.express.use(`/${ENDPOINT}`, (req, res) => {
      if (!req.query.code) {
        if (!req.query.error) {
          res.redirect(this.authUrl)
        }
        else
          res.send('access denied')
      }
    })
    return `http://localhost:${HTTP_PORT}/${ENDPOINT}`
  }

  getToken(code) {
    let params = Object.assign({code}, this.credentials)

    return this.client.authorizeAsync(params)
      .catch((err) => Promise.reject(err.message))
  }

  setCredentials(tokens) {
    this.credentials = {
      'access_token': tokens['access_token'],
      'client_id': this.credentials['client_id'],
      'client_secret':  this.credentials['client_secret']
    }
  }

  extendAccesToken() {
    return this.client.extendAccessTokenAsync(this.credentials)
  }
}
