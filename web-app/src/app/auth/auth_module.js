import angular from 'angular'
import hello from 'hellojs'

import AuthController from './auth_controller'
import AuthService from './auth_service'
import {html as template} from './auth.jade!'
import './auth.css!'

const name = 'auth'

const component = {
  template,
  controller: AuthController,
  controllerAs: 'vm',
}

const config = ($stateProvider, STOREIT) => {
  'ngInject'

  $stateProvider
    .state(name, {
      url: `/${name}`,
      component: name
    })

  let credentials = {
    facebook: STOREIT.facebookId,
    google: STOREIT.googleId
  }
  let options = {
    'redirect_uri': `${window.location.origin}/#/auth`
  }

  hello.init(credentials, options)
}

const DEPENDENCIES = []
export default angular.module(`storeit.app.${name}`, DEPENDENCIES)
  .value('Facebook', hello('facebook'))
  .value('Google', hello('google'))
  .service('Auth', AuthService)
  .component(name, component)
  .config(config)
  .name
