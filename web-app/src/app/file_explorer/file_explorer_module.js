import angular from 'angular'

import FileExplorerController from './file_explorer_controller'
import FilesService from './files_service'
import {html as template} from './file_explorer.jade!'
import './file_explorer.css!'

const name = 'files'

const component = {
  template,
  controller: FileExplorerController,
  controllerAs: 'vm',
}

const config = ($stateProvider) => {
  $stateProvider
    .state(name, {
      url: `/${name}`,
      component: name
    })
}

const DEPENDENCIES = []
export default angular.module('storeit.app.file-explorer', DEPENDENCIES)
  .service('FilesService', FilesService)
  .component(name, component)
  .config(config)
  .name
