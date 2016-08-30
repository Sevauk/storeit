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

  login(network) {
    return this.join(authTypes[network])
  }

  join(authType, accessToken) {
    return this.client.request('JOIN', {authType, accessToken})
  }
}
