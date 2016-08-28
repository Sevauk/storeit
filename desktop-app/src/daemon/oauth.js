import open from 'open'
import express from 'express'
import gapi from 'googleapis'
import fbgraph from 'fbgraph'

import {logger} from '../../lib/log'
import settings from './settings'

fbgraph = Promise.promisifyAll(fbgraph)
gapi = Promise.promisifyAll(gapi)

const REDIRECT_URI = 'http://localhost:7777/'
const HTTP_PORT = 7777

class OAuthProvider {
  constructor() {
    this.express = express()
    this.loadTokens()
  }

  waitAuthorized() {
    return new Promise((resolve, reject) => {
      this.express.use('/', (req, res) => {
        let msg = 'Thank you for authenticating, you can now quit this page.'
        res.send(`StoreIt: ${msg}`)

        this.http.close()
        logger.info('Access granted, Http server stopped')

        let code = req.query.code
        code != null ? resolve(code) : reject({err: 'could not get code'})
      })

      this.http = this.express.listen(HTTP_PORT)
      logger.info(`Http server listening on port ${HTTP_PORT}`)
    })
  }

  loadTokens() {
    this.authSettings = settings.get('auth')
  }

  oauth(opener=open) {
    let url = this.generateAuthUrl()
    let authorized = Promise.resolve(url ? this.waitAuthorized() : true)
    if (url) opener(url)

    return authorized
      .then((code) => this.getToken(code))
      .then((tokens) => this.mangeTokens(tokens))
      .catch((err) => logger.error(err))
  }

  saveTokens(type, tokens) {
    settings.setTokens(type, tokens)
    settings.save()
  }
}

export class GoogleService extends OAuthProvider {
  constructor() {
    super()

    const {GAPI_CLIENT_ID, GAPI_CLIENT_SECRET} = process.env

    this.client = new gapi.auth.OAuth2(GAPI_CLIENT_ID,
      GAPI_CLIENT_SECRET, REDIRECT_URI)
    if (this.hasRefreshToken()) {
      this.client.setCredentials(settings.getTokens('gg'))
    }
  }

  generateAuthUrl() {
    if (this.hasRefreshToken()) return null

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
    this.saveTokens('gg', tokens)
  }

  hasRefreshToken() {
    return settings.getTokens('gg') != null
  }
}

export class FacebookService extends OAuthProvider {
  constructor() {
    super()

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
    this.saveTokens('fb', tokens)
    if (extended) return tokens

    return this.client.extendAccessTokenAsync(this.prepareToken())
      .then((tokens) => this.manageTokens(tokens, true))
  }

  prepareToken() {
    return {
      'access_token': settings.getTokens('fb')['access_token'],
      'client_id': this.credentials['client_id'],
      'client_secret':  this.credentials['client_secret']
    }
  }
}
