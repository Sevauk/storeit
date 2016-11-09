//const stormpath = require('stormpath')
import stormpath from 'stormpath'
import settings from './settings.js'

const apiKey = new stormpath.ApiKey(
  settings['STORMPATH_CLIENT_APIKEY_ID'],
  settings['STORMPATH_CLIENT_APIKEY_SECRET']
)

const client = new stormpath.Client({apiKey})

const applicationHref = settings['STORMPATH_APPLICATION_HREF']

client.getApplication(applicationHref, (err, application) => {

  console.log('Application:', application)

  const createAccount = (email, password) => {

    const account = {
      email,
      givenName: 'Adri',
      middleName: 'Dridri',
      password,
      customData: {
        dataLimit: 5
      }
    }

    application.createAccount(account, (err, createdAccount) => {
      console.log(err)
      console.log('Account:', createdAccount)
    })
  }

  createAccount('adrien.morel@me.com', 'K776xdxd')
})
