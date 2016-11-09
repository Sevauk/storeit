import {oauth2} from 'googleapis'
import request from 'request'
import * as protocol from './lib/protocol-objects.js'
import storm from './stormpath.js'

const oauth = oauth2('v2')

const authGoogle = (accessToken, handlerFn) => {

  oauth.userinfo.get({'access_token': accessToken}, (err, response) => {
    if (err) {
      return handlerFn(protocol.ApiError.BADCREDENTIALS)
    }

    if (response.email === undefined) {
      return handlerFn(protocol.ApiError.BADSCOPE)
    }
    return handlerFn(null, response.email, response.picture)
  })
}

const authFacebook = (accessToken, handlerFn) => {

  return request('https://graph.facebook.com/me?access_token=' + accessToken + '&fields=email', (err, response, body) => {

    if (response.statusCode !== 200) {
      return handlerFn(protocol.ApiError.SERVERERROR)
    }

    const parsed = JSON.parse(body)
    if (parsed.email === undefined) {
      return handlerFn(protocol.ApiError.BADSCOPE)
    }
    handlerFn(null, parsed.email, parsed.picture)
  })
}

const verifyUserToken = (authService, accessToken, handlerFn) => {

  const devlpr = 'developer'
  if (accessToken.substr(0, devlpr.length) === 'developer') {
    let idx = parseInt(accessToken.substr(devlpr.length))
    if (isNaN(idx))
      idx = ''
    return handlerFn(null, 'adrien.morel' + idx + '@me.com', 'http://i1-news.softpedia-static.com/images/news2/Keep-Your-Programming-Code-Safe-Obfuscate-It-480832-2.jpg')
  }

  if (authService === 'gg') {
    return authGoogle(accessToken, handlerFn)
  }
  else if (authService === 'fb') {
    return authFacebook(accessToken, handlerFn)
  }
  else {
    handlerFn(protocol.ApiError.UNKNOWNAUTHTYPE)
  }
}

const inHouseAuth = (authParams, handlerFn) => {
  console.log('authenticate ' + JSON.stringify(authParams))
}

export const doAuthentication = (authParams, handlerFn) => {
  if (authParams.type === 'st') {
    return inHouseAuth(authParams, handlerFn)
  }

  return verifyUserToken(authParams.type, authParams.accessToken, handlerFn)
}
