import 'angular-material/angular-material.css!'

import angular from 'angular'
import 'angular-ui-router'
import 'angular-animate'
import 'angular-aria'
import 'angular-material'


import storeitClient from 'app/core/client_service'
import constants from './app/core/constants.js'
import app from './app/app.js'

let coreConfig = ($locationProvider) => {
  'ngInject'
  $locationProvider.html5Mode(true)
}

let run = ($rootScope) => {
  'ngInject'
  /* eslint no-unused-vars:"off" */
  // Promise.setScheduler(cb => $rootScope.$evalAsync(cb)) // FIXME
}

const DEPENDENCIES = [
  'ui.router',
  'ngMaterial',
  constants,
  storeitClient,
  app
]
let storeit = angular.module('storeit', DEPENDENCIES)
  .config(coreConfig)
  .run(run)

angular.element(document).ready(() => {
  let appContainer = document.getElementById('app-container')
  angular.bootstrap(appContainer, [storeit.name])
})

export default storeit
