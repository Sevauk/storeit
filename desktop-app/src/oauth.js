import open from 'open'
import express from 'express'
import gapi from 'googleapis'
import fbgraph from 'fbgraph'

import {logger} from '../lib/log'
import settings from './settings'

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

  oauth(opener=open) {
    if (this.hasRefreshToken())
      return this.getToken()

    let url = this.client.generateAuthUrl({
      scope: 'email',
      access_type: 'offline' // eslint-disable-line camelcase
    })
    let tokenPromise = this.waitAuthorized()
      .then((code) => this.getToken(code))

    opener(url)
    return tokenPromise
  }

  getToken(code) {
    return new Promise((resolve, reject) => {
      let manageTokens = (err, tokens) => {
        if(!err) {
          this.client.setCredentials(tokens)
          this.saveTokens('gg', tokens)
          resolve(tokens)
        }
        else {
          logger.error(err)
          reject(err)
        }
      }

      if (code != null) {
        logger.info('exchanging code against access token')
        this.client.getToken(code, manageTokens)
      }
      else {
        logger.info('refreshing token')
        this.client.refreshAccessToken(manageTokens)
      }
    })
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

  oauth(opener=open) {
    const ENDPOINT = 'auth/fb'
    this.express.use(`/${ENDPOINT}`, (req, res) => {
      if (!req.query.code) {
        if (!req.query.error)
          res.redirect(this.authUrl)
        else
          res.send('access denied')
      }
    })
    let tokenPromise = this.waitAuthorized()
      .then((code) => this.getToken(code))
    opener(`http://localhost:${HTTP_PORT}/${ENDPOINT}`)
    return tokenPromise
  }

  getToken(code) {
    return new Promise((resolve, reject) => {
      let params = Object.assign({code}, this.credentials)
      let extended = false

      /*
      * Is called twice
      */
      let manageTokens = (err, tokens) => {
        if (!err) {
          this.saveTokens('fb', tokens)
          if (!extended)
            this.client.extendAccessToken(this.prepareToken(), manageTokens)
          else
            resolve(tokens)
        }
        else {
          logger.error(err.message)
          reject(err)
        }
        extended = !extended // becomes true after first call back
      }

      this.client.authorize(params, manageTokens)
    })
  }

  prepareToken() {
    return {
      'access_token': settings.getTokens('fb')['access_token'],
      'client_id': this.credentials['client_id'],
      'client_secret':  this.credentials['client_secret']
    }
  }
}
