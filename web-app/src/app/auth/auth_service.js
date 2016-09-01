const authTypes = {
  'facebook': 'fb',
  'google': 'gg'
}

export default class AuthService {

  constructor(StoreItClient) {
    'ngInject'

    this.client = StoreItClient
  }

  devLogin() {
    return this.join('gg', 'developer')
  }

  login(network, token) {
    return this.join(authTypes[network], token)
  }

  join(authType, accessToken) {
    window.join = () => {
      return this.client.request('JOIN', {authType, accessToken, hosting: {}})
    }
    return Promise.resolve()
  }
}
