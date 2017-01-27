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

  join(type, accessToken) {
    const authParams = {auth: {type, accessToken}, hosting: {}}
    localStorage.setItem('authParams', JSON.stringify(authParams))
    return this.client.request('JOIN', authParams)
  }
}
