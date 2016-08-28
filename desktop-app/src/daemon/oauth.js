import open from 'open'
import express from 'express'
import gapi from 'googleapis'
import fbgraph from 'fbgraph'

import logger from '../../lib/log'
import settings from './settings'

Promise.promisifyAll(fbgraph)
Promise.promisifyAll(gapi)

const REDIRECT_URI = 'http://localhost:7777/'
const HTTP_PORT = 7777

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
      .then((code) => this.getToken(code))
      .then((tokens) => this.mangeTokens(tokens))
      .then((tokens) => this.saveTokens(tokens))
      .catch((err) => logger.error(err))
  }

  waitAuthorized() {
    return new Promise((resolve) => {
      this.express.use('/', (req, res) => resolve(this.getCode(req, res)))
      this.http = this.express.listen(HTTP_PORT)
      logger.info(`Http server listening on port ${HTTP_PORT}`)
    })
  }

  getCode(req, res) {
    let msg = 'Thank you for authenticating, you can now quit this page.'
    res.send(`StoreIt: ${msg}`)

    this.http.close()
    logger.info('Access granted, Http server stopped')

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
    super('gg')

    const {GAPI_CLIENT_ID, GAPI_CLIENT_SECRET} = process.env

    this.client = new gapi.auth.OAuth2(GAPI_CLIENT_ID,
      GAPI_CLIENT_SECRET, REDIRECT_URI)

    if (this.hasTokens()) this.client.setCredentials(this.tokens)
  }

  generateAuthUrl() {
    if (this.hasToken()) return null

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

  manageTokens(tokens) {
    this.client.setCredentials(tokens)
  }
}

export class FacebookService extends OAuthProvider {
  constructor() {
    super('fb')

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
        if (!req.query.error)
          res.redirect(this.authUrl)
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

  manageTokens(tokens, extended=false) {
    if (extended) return tokens

    return this.client.extendAccessTokenAsync(this.prepareToken())
      .then((tokens) => this.manageTokens(tokens, true))
  }

  prepareToken() {
    return {
      'access_token': this.tokens['access_token'],
      'client_id': this.credentials['client_id'],
      'client_secret':  this.credentials['client_secret']
    }
  }
}
