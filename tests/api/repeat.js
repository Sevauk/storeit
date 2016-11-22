const bluebird = require('bluebird')

// to task every seconds for max seconds until task resolves
const every = (seconds, max, task) =>
  task()
    .catch((e) => {
        return max > 0 ?
          bluebird.delay(seconds * 1000).then(() => every(seconds, max - seconds, task)) :
          bluebird.reject(new Error('repeat task timed out.'))
    })

module.exports = {
  every
}
