import {logger} from './lib/log.js'

logger.setLevel('error')

import {expect} from 'chai'
import WebSocket from 'ws'
import * as fs from 'fs'
import * as api from './lib/protocol-objects.js'
import * as user from './user.js'
import * as tool from './tool.js'
import * as store from './store.js'
import './ws.js'

const USERHASHES = [
  'Qmco5NmRNMit3V2u3whKmMAFaH4tVX4jPnkwZFRdsb4dtT',
  'QmSdZaa9KWGBc9m8mFwUiZGo2YkrQgxoUoRU7EB4VmeQzp',
]

class fakeUser {

  send(obj) {
    this.ws.send(JSON.stringify(obj))
  }

  constructor(accessToken, msgHandler) {
    this.ws = new WebSocket('ws://localhost:7641')
    this.accessToken = accessToken
    this.ws.on('open', () => {
      this.join()
    })
    this.msgHandler = msgHandler

    this.ws.on('message', (data) => {
      const obj = JSON.parse(data)

      if (obj.command === 'RESP')
        this.msgHandler(obj)
    })
  }

  join() {
    this.send(new api.Command('JOIN', {
      authType: 'fb',
      accessToken: this.accessToken,
      hashes: USERHASHES
    }))
  }

  leave() {
    this.ws.close()
  }
}

const expectOkResponse = (obj) => {

  try {
    expect(obj.code).to.equal(0)
  }
  catch (e) {
    console.log(e)
    if (obj) {
      console.log(obj)
    }
  }
}

const expectUsualJoinResponse = (obj) => {

  expectOkResponse(obj)
  expect(obj.parameters.home.path).to.equal('/')
}

const expectErrorResponse = (obj) => {
  expect(obj.code).to.not.equal(0)
  expect(obj.command).to.equal('RESP')
}

let fakeA = undefined
let fakeB = undefined

describe('simple connection', () => {

  try {
    fs.unlinkSync('./storeit-users/adrien.morel@me.com')
  }
  catch (err) {
    console.log('nothing to remove')
  }

  it('should get JOIN response', (done) => {
    fakeA = new fakeUser('developer', (data) => {

      expect(store.storeTable.get(USERHASHES[0]).has(0)).to.equal(true)
      expect(store.storeTable.get(0).has(USERHASHES[0])).to.equal(true)
      expectUsualJoinResponse(data)
      done()
    })
  })

  it('should fail to connect client', (done) => {
    fakeB = new fakeUser('invalid_access_token', (data) => {
      expectErrorResponse(data)
      done()
    })
  })

  it('should connect another client', (done) => {
    fakeB = new fakeUser('developer', (data) => {
      expectUsualJoinResponse(data)
      done()
    })
  })

  it('should have correct number of connected user', () => {
    expect(user.getUserCount()).to.equal(1)
    expect(user.getConnectionCount()).to.equal(2)
  })

})

describe('protocol file commands', () => {

  it('should disconnect user without issue', (done) => {
    fakeB.ws.on('close', () => {
      setTimeout(() => {
        expect(user.getConnectionCount()).to.equal(1)
        expect(user.getUserCount()).to.equal(1)
        expect(Object.keys(store.storeTable.map1).length).to.equal(1)
        done()
      }, 10) // wait for server to take action
    })

    fakeB.leave()
  })

  let userTree = user.makeBasicHome()

  const checkUserTree = () => {
    expect(userTree).to.deep.equal(user.users['adrien.morel@me.com'].home)
  }

  it('should FADD correctly', (done) => {

    const FADDContent = new api.FileObj('/foo', null, {
      'bar.txt': new api.FileObj('/foo/bar.txt')
    })

    fakeA.msgHandler = (data) => {
      expectOkResponse(data)

      userTree.files['foo'] = FADDContent

      checkUserTree()
      done()
    }

//    this.send({"command":"FADD","parameters":{"files":[{"IPFSHash":"QmQxbFWVWcmVJmsPimPpW36evA7U1jdaKZPh7g7jpQyQU7","files":{},"isDir":false,"metadata":"","path":"/hangouts_incoming_call.ogg"}]},"uid":1})
    fakeA.send(new api.Command('FADD', {
      files: [
        FADDContent
      ]
    }))
  })

  it('should FMOV correctly (simple rename)', (done) => {

    fakeA.msgHandler = (data) => {
      expectOkResponse(data)
      checkUserTree()
      done()
    }

    const tree = userTree.files['foo'].files['bar.txt']
    delete userTree.files['foo'].files['bar.txt']
    userTree.files['foo'].files['renamed.txt'] = tree
    userTree.files['foo'].files['renamed.txt'].path = '/foo/renamed.txt'

    fakeA.send(new api.Command('FMOV', {
      src: '/foo/bar.txt',
      dest: '/foo/renamed.txt'
    }))

  })

  let oldTree = null

  it('should FMOV correctly (directory move)', (done) => {

    let responseCount = 1

    fakeA.msgHandler = (data) => {
      expectOkResponse(data)
      checkUserTree()
      if (responseCount-- === 0) {
        done()
      }
    }

    const FADDContent = new api.FileObj('/foo/newdir', null, {
      'anotherdir': new api.FileObj('/foo/newdir/anotherdir', null, {
        'foobar.txt': new api.FileObj('/foo/newdir/anotherdir/foobar.txt'),
        'girl.mov': new api.FileObj('/foo/newdir/anotherdir/girl.mov')
      })
    })

    userTree.files['foo'].files['newdir'] = FADDContent

    fakeA.send(new api.Command('FADD', {
      files: [
        FADDContent
      ]
    }))

    oldTree = JSON.parse(JSON.stringify(userTree))

    const tree = userTree.files['foo'].files['newdir']
    delete userTree.files['foo'].files['newdir']
    userTree.files['newdir'] = tree
    userTree.files['newdir'].path = '/newdir'
    userTree.files['newdir'].files['anotherdir'].path = '/newdir/anotherdir'
    userTree.files['newdir'].files['anotherdir'].files['foobar.txt'].path = '/newdir/anotherdir/foobar.txt'
    userTree.files['newdir'].files['anotherdir'].files['girl.mov'].path = '/newdir/anotherdir/girl.mov'

    fakeA.send(new api.Command('FMOV', {
      src: '/foo/newdir',
      dest: '/newdir'
    }))
  })

  it('should FMOV correctly (another directory move)', (done) => {
    fakeA.msgHandler = (data) => {
      expectOkResponse(data)
      checkUserTree()
      done()
    }

    userTree = oldTree

    fakeA.send(new api.Command('FMOV', {
      src: '/newdir',
      dest: '/foo/newdir'
    }))
  })

  it('should FDEL correctly', (done) => {

    fakeA.msgHandler = (data) => {
      expectOkResponse(data)
      checkUserTree()
      done()
    }

    delete userTree.files['foo'].files['newdir'].files['anotherdir']
    delete userTree.files['readme.txt']
    fakeA.send(new api.Command('FDEL', {
      files: ['/foo/newdir/anotherdir', '/readme.txt']
    }))
  })
})

describe('internal server tools', () => {

  it('test of our double lookup hash table', (done) => {
    const table = new tool.TwoHashMap()

    table.add('adrien.morel@me.com', 'hash1')
    table.add('adrien.morel@me.com', 'hash2')
    table.add('adrien.morel@me.com', 'hash3')
    table.add('james.bond@me.com', 'hash2')
    table.add('james.bond@me.com', 'hash4')
    table.add('jamie.lannister@me.com', 'hash2')
    table.add('jamie.lannister@me.com', 'hash8')
    table.add('jamie.lannister@me.com', 'hash1')

    const selectUser = table.selectA('hash8', 2)
    expect(selectUser.size).to.equal(2)
    expect(selectUser.has('james.bond@me.com')).to.equal(true)
    expect(selectUser.has('adrien.morel@me.com')).to.equal(true)

    expect(table.get('james.bond@me.com').has('hash4')).to.equal(true)
    expect(table.get('hash2').has('adrien.morel@me.com')).to.equal(true)

    table.remove('hash2')

    expect(table.get('james.bond@me.com').has('hash2')).to.equal(false)

    table.remove('hash4')

    expect(table.get('james.bond@me.com')).to.equal(undefined)
    expect(table.get('hash4')).to.equal(undefined)


    table.add('toto@hotmail.fr', 'hash3')
    table.add('james.bond@me.com', 'hash3')
    table.remove('hash8')

    expect(table.test('toto@hotmail.fr', 'hash3')).to.equal(true)
    expect(table.count('hash3')).to.equal(3)
    expect(table.test('jamie.lannister@me.com', 'hash1')).to.equal(true)
    expect(table.test('jamie.lannister@me.com', 'hash8')).to.equal(false)
    expect(table.test('hash1', 'jamie.lannister@me.com')).to.equal(true)
    expect(table.test('hash1', 'adrien.morel@me.com')).to.equal(true)

    table.remove('adrien.morel@me.com')

    expect(table.map2).to.deep.equal({
      hash1: new Set(['jamie.lannister@me.com']),
      hash3: new Set(['toto@hotmail.fr', 'james.bond@me.com']),
    })

    done()
  })
})
