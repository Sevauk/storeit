import hello from 'hellojs'

export default class AuthController
{
  constructor($state, Facebook, Auth) {
    'ngInject'

    this.facebook = Facebook
    this.auth = Auth
    this.$state = $state

    hello.on('auth.login', () => this.getProfile('facebook'))
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
