const client = require('./api/client.js')
const file = require('./api/file.js')

describe('StoreIt client', () => { // eslint-disable-line

  it('should run multiple clients',() => // eslint-disable-line
    Promise.all([
      client.run(0),
      client.run(3),
      client.run(0),
      client.run(2),
      client.run(3),
      client.run(3),
    ]))
  it('should remove everything', () => file.remove(0, '*')) // eslint-disable-line
  /*
  it('should sync a txt file', () => file.add(3, 'helloworld.txt', 'hello.txt')) // eslint-disable-line
  it('should sync a big file', () => file.add(0, 'data10m', 'big')) // eslint-disable-line
  it('should sync multiple files and subfiles', () => // eslint-disable-line
    file.add(0, 'data10m', 'big')
      .then(() => file.add(0, 'directory', 'foo'))
      .then(() => file.add(0, 'directory', 'foo/bar'))
      .then(() => file.add(0, 'freeman.png', 'foo/bar/freeman.png')))
  it('should kill client 0. Make its files disappear, and retreive them from other clients', () => // eslint-disable-line
    client.kill(0)
      .then(() => client.run(0))
      .then(() => file.exists(0, 'big', file.asset('data10m'))))
      */
})
