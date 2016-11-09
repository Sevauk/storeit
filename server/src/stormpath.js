//const stormpath = require('stormpath')
import stormpath from 'stormpath'
import {settings} from './settings.js'
import bluebird from 'bluebird'

let appli = undefined

const getApp = () => new Promise((resolve, reject) => {

  if (appli) return resolve(appli)

  const apiKey = new stormpath.ApiKey(
    settings('STORMPATH_CLIENT_APIKEY_ID'),
    settings('STORMPATH_CLIENT_APIKEY_SECRET')
  )

  const client = new stormpath.Client({apiKey})
  const appHref = settings('STORMPATH_APPLICATION_HREF')

  client.getApplication(appHref, (err, app) => {
    if (err) reject(err)
    appli = app
    bluebird.promisifyAll(appli)
    resolve(appli)
  })
})

export const createAccount = (email, password) =>
  getApp()
    .then(app => app.createAccountAsync({
      email,
      givenName: 'null',
      middleName: 'null',
      password,
      customData: {
        dataLimit: 5
      }
    }))
    .then(createdAccount => console.log('account :' + createdAccount))


export const authenticateAccount = (email, password) =>
  getApp()
    .then(app => app.authenticateAccountAsync({username: email, password}))
    .then(result => new Promise((resolve, reject) => {
      result.getAccount((err, account) => {
        if (err) return reject(err)
        resolve(account)
      })
    }))
