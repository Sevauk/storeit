import hello from 'hellojs'

export default class AuthController
{
  constructor($state, Facebook, Google, Auth) {
    'ngInject'

    this.facebook = Facebook
    this.google = Google
    this.auth = Auth
    this.$state = $state
  }

  login(network, profile) {
    console.log(profile) // TODO
    let token = this[network].getAuthResponse().access_token
    this.auth.login(network, token)
      .then(() => this.$state.go('files'))
      .catch(err => console.error(err))
  }

  online(session) {
    let currentTime = (new Date()).getTime() / 1000
    return session && session.access_token && session.expires > currentTime
  }

  developer() {
    this.auth.devLogin()
      .then(() => this.$state.go('files'))
  }

  oauth(network) {
    this[network].login()
    hello.on('auth.login', (res) => this.getProfile(res.network))
  }

  getProfile(network) {
    this[network].api('/me').then((res) => this.login(network, res))
  }
}
