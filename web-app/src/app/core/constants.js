import angular from 'angular'

const G_ADDR = '.apps.googleusercontent.com'

const STOREIT = {
  facebookId: '615629721922275',
  googleId: `279687106087-15n5a2lvpiro2sjmfcug6ch9v732ak3j${G_ADDR}`
}

export default angular.module('storeit.constants', [])
  .constant('STOREIT', STOREIT)
  .name
