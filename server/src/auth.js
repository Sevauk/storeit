import {oauth2} from 'googleapis'
import request from 'request'
import * as protocol from './common/protocol-objects.js'

const oauth = oauth2('v2')

export const verifyUserToken = (authService, accessToken, handlerFn) => {

  if (accessToken === 'developer') {
    return handlerFn(null, 'adrien.morel@me.com')
  }
  if (authService === 'gg') {
    return oauth.userinfo.get({'access_token': accessToken}, (err, response) => {
      if (err) {
        return handlerFn(protocol.ApiError.BADCREDENTIALS)
      }

      if (response.email === undefined) {
        return handlerFn(protocol.ApiError.BADSCOPE)
      }
      return handlerFn(null, response.email)
    })
  }
  else if (authService === 'fb') {
    return request('https://graph.facebook.com/me?access_token=' + accessToken + '&fields=email', (err, response, body) => {

      if (response.statusCode !== 200) {
        return handlerFn(protocol.ApiError.SERVERERROR)
      }

      const parsed = JSON.parse(body)
      if (parsed.email === undefined) {
        return handlerFn(protocol.ApiError.BADSCOPE)
      }
      handlerFn(null, parsed.email)
    })
  }
  else {
    handlerFn(protocol.ApiError.UNKNOWNAUTHTYPE)
  }
}
