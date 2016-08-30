import hello from 'hellojs'

export default class AuthController
{
  constructor($state, Facebook, Google, Auth) {
    'ngInject'

    this.facebook = Facebook
    this.google = Google
    this.auth = Auth
    this.$state = $state

    hello.on('auth.login', (res) => this.getProfile(res.network))
  }

  login(profile) {
    console.log(profile) // TODO
    this.auth.login()
      .then(() => this.$state.go('files'))
      .catch(err => console.error(err))
  }

  oauth(network) {
    this[network].login()
  }

  getProfile(network) {
    this[network].api('/me').then((res) => this.login(res))
  }
}
