import {logger} from './log.js'

logger.transports.console.level = 'error'

import {expect} from 'chai'
import WebSocket from 'ws'
import * as api from './protocol-objects'
import * as user from './user.js'
import './ws.js'

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
      this.msgHandler(data)
    })
  }

  join() {
    this.send(new api.Command('JOIN', {
      authType: 'fb',
      accessToken: this.accessToken
    }))
  }

  leave() {
    this.ws.close()
  }
}

const expectOkResponse = (data) => {
  const obj = JSON.parse(data)

  expect(obj.code).to.equal(0)
}

const expectUsualJoinResponse = (data) => {

  const obj = JSON.parse(data)

  expectOkResponse(data)
  expect(obj.parameters.home.path).to.equal('/')
}

const expectErrorResponse = (data) => {
  const obj = JSON.parse(data)

  expect(obj.code).to.not.equal(0)
  expect(obj.command).to.equal('RESP')
}

let fakeA = undefined
let fakeB = undefined

/*
describe('OAuth login/registering', () => {
  it('should connect with google', () => {
    fakeGoogle = new fakeUser()
  })
})
*/

describe('simple connection', () => {

  it('should get JOIN response', (done) => {
    fakeA = new fakeUser('developer', (data) => {
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
        done()
      }, 10) // wait for server to take action
    })

    fakeB.leave()
  })

  const userTree = user.makeBasicHome()

  const checkUserTree = () => {
    expect(userTree).to.deep.equal(user.users['adrien.morel@me.com'].home)
  }

  it('should FADD correctly', (done) => {

    const FADDContent = api.makeFileObj('/foo', null, {
      'bar.txt': api.makeFileObj('/foo/bar.txt')
    })

    fakeA.msgHandler = (data) => {
      expectOkResponse(data)

      userTree.files['foo'] = FADDContent

      checkUserTree()
      done()
    }

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

  it('should FMOV correctly (directory move)', (done) => {

    let responseCount = 1

    fakeA.msgHandler = (data) => {
      expectOkResponse(data)
      checkUserTree()
      if (responseCount-- === 0) {
        done()
      }
    }

    const FADDContent = api.makeFileObj('/foo/newdir', null, {
      'anotherdir': api.makeFileObj('/foo/newdir/anotherdir', null, {
        'foobar.txt': api.makeFileObj('/foo/newdir/anotherdir/foobar.txt'),
        'girl.mov': api.makeFileObj('/foo/newdir/anotherdir/girl.mov')
      })
    })

    userTree.files['foo'].files['newdir'] = FADDContent

    fakeA.send(new api.Command('FADD', {
      files: [
        FADDContent
      ]
    }))

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

  it('should FDEL correctly', (done) => {

    fakeA.msgHandler = (data) => {
      expectOkResponse(data)
      checkUserTree()
      done()
    }

    delete userTree.files['newdir'].files['anotherdir']
    delete userTree.files['readme.txt']
    fakeA.send(new api.Command('FDEL', {
      files: ['/newdir/anotherdir', '/readme.txt']
    }))
  })
})
