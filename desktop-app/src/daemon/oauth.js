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
    this.id = Math.random() * 100
    this.express = express()
    this.http = this.express.listen(HTTP_PORT)
    this.http.addListener('connection', (stream) => stream.setTimeout(2000))
    this.type = type
    this.tokens = settings.getTokens(type)
  }

  oauth(opener=open) {
    try {
      let userIntent = null
      const url = this.generateAuthUrl()
      if (url) {
        userIntent = this.waitAuthorized()
        opener(url)
      }
      else {
        userIntent = Promise.resolve()
      }
      return userIntent
        .tap(() => logger.debug('[OAUTH] get token'))
        .then(code => this.getToken(code))
        .tap(() => logger.debug('[OAUTH] setting credentials'))
        .tap(tokens => this.setCredentials(tokens))
        .tap(() => logger.debug('[OAUTH] extending access token'))
        .then(tokens => this.extendAccesToken(tokens))
        .tap(() => logger.debug('[OAUTH] saving...'))
        .tap(tokens => this.saveTokens(tokens))
        .tap(() => logger.debug('[OAUTH] tokens saved'))
        .catch(e => {
          logger.error(`[OAUTH] ${this.type} authorization failed: ${e}`)
          throw new Error(e)
        })
    }
    catch (e) {
      return Promise.reject(new Error(e))
    }

  }

  waitAuthorized() {
    return new Promise((resolve, reject) => {
      this.express.use('/', (req, res) => {
        const code = req.query.code
        const msg = 'Thank you for authenticating, you can now quit this page.'
        res.send(`StoreIt: ${msg}`)
        this.stopHttpServer()

        if (code != null) {
          logger.debug('[OAUTH] access granted')
          resolve(code)
        }
        else {
          logger.debug('[OAUTH] access failure')
          reject(new Error('[OAUTH] could not get code'))
        }
      })
    })
  }

  stopHttpServer() {
    this.http.close(() => logger.debug('[OAUTH] server closed'))
  }

  saveTokens(tokens) {
    this.tokens = tokens
    settings.setTokens(this.type, tokens)
    settings.save()
    logger.debug('[OAUTH] tokens saved')
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
    // FIXME
    // if (this.hasTokens()) this.client.setCredentials(this.tokens)
  }

  generateAuthUrl() {
    // FIXME
    // if (this.hasTokens()) return null

    return this.client.generateAuthUrl({
      scope: 'email',
      'access_type': 'offline'
    })
  }

  getToken(code) {
    if (code != null) {
      logger.info(`[OAUTH:gg] exchanging code ${code} against access token`)
      return this.client.getTokenAsync(code)
    }
    else {
      return Promise.resolve(this.tokens)
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
  }

  generateAuthUrl() {
    return this.authUrl
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
