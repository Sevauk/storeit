import angular from 'angular'

import {html as template} from './app.jade!'
import './app.css!'

import auth from './auth/auth_module'
import files from './file_explorer/file_explorer_module'

const DEPENDENCIES = [
  auth,
  files,
]

const appComponent = {template}

const config = ($urlRouterProvider) => {
  'ngInject'
  $urlRouterProvider.otherwise('/auth')
}

export default angular.module('storeit.app', DEPENDENCIES)
  .component('app', appComponent)
  .config(config)
  .name
