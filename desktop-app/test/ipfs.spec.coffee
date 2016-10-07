require './lib/init'
userFile = importDfl 'user-file'
IPFSNode = importDfl 'ipfs'
spawn = require('child_process').spawn

child = spawn 'ipfs', ['daemon']
child.on 'error', (err) -> log.error 'IPFS Error:', err
fs = Promise.promisifyAll(require 'fs')

ipfs = new IPFSNode()
filePath = '/foo'
fileHash = 'QmW3J3czdUzxRaaN31Gtu5T1U5br3t631b8AHdvxHdsHWg'
fileData = 'bar'

describe 'IPFS', ->

  before (done) ->
    @timeout 60000
    ipfs.connect()
      .then -> userFile.clear()
      .then -> done()

  after -> userFile.clear()

  describe '#ready()', ->
    it 'should resolve when node is ready', (done) ->
      ipfs.ready().should.be.fulfilled.and.notify(done)

  describe '#add()', ->
    it 'should resolve to an array of chunks', ->
      @timeout 10000
      userFile.create(filePath, fileData)
        .then -> ipfs.add(filePath)
        .then (res) -> res.forEach (chunk) ->
          chunk.should.have.ownProperty 'Name'
          chunk.should.have.ownProperty 'Hash'

  describe '#rm()', ->
    it 'should return a promise fulfilled when operation is done', (done) ->
      ipfs.rm('test').should.be.fulfilled.and.notify(done)

  describe '#getFileHash()', ->
    it 'should return the file hash', ->
      ipfs.getFileHash(filePath).should.eventually.equal fileHash

  describe '#hashMatch()', ->
    it 'should check whether some hash corresponds to the file', ->
      ipfs.hashMatch(filePath, fileHash).should.eventually.be.true
      ipfs.hashMatch(filePath, fileHash + '42').should.eventually.be.false

  describe '#get()', ->
    it 'should resolve to the file buffer', ->
      @timeout 5000
      ipfs.get(fileHash).should.eventually.eql Buffer(fileData)

  describe '#download()', ->
    it 'should create the file in user store with the fetched buffer', ->
      @timeout 5000
      p = '/bar'
      ipfs.download p, fileHash
        .then -> fs.readFileAsync userFile.absolutePath(p), 'utf8'
        .should.eventually.equal fileData
