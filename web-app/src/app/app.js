import angular from 'angular'

import {html} from './app.jade!'
import './app.css!'

import auth from './auth/auth_module'
import fileExplorer from './file_explorer/file_explorer_module'

const DEPENDENCIES = [
  auth,
  fileExplorer,
]

let appComponent = {
  template: html,
  $routeConfig: [
    {path: '/auth', name: 'Auth', component: 'auth', useAsDefault: true},
    {path: '/files', name: 'FileExplorer', component: 'fileExplorer'},
  ],
}

export default angular.module('storeit.app', DEPENDENCIES)
  .component('app', appComponent)
  .name
