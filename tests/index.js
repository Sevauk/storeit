const client = require('./api/client.js')
const file = require('./api/file.js')

const clients = [
  client.run(0),
  client.run(0),
  client.run(2),
  client.run(2)
]

Promise.all(clients)
  .then(() => file.add(0, 'helloworld.txt', 'hello'))
  .then(() => file.add(0, 'directory', 'directory'))
  .then(() => {
    console.log('success!')
    client.kill()
    process.exit()
  })
  .catch((err) => console.log(err))
