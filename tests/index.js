const api = require('./api.js')

api.runClient(0)
  .then((cli) => console.log('client running.'))
  .catch((err) => console.log(err))
