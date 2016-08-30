import angular from 'angular'

const STOREIT = {
  facebookId: '615629721922275',
  googleId: '279687106087-5j6jj4o1f38v435973q1805p0gd9r0nf'
}

export default angular.module('storeit.constants', [])
  .constant('STOREIT', STOREIT)
  .name
