require './lib/init'
userFile = importDfl 'user-file'
ipfs = (require '../build/daemon/ipfs')
settings = importDfl 'settings'
store = settings.getStoreDir()

path = require('path')
spawn = require('child_process').spawn
fs = Promise.promisifyAll(require 'fs')

del = require 'del'

resetStore = ->
  rm '-rf', store
  mkdir store

describe 'User File', ->

  beforeEach -> resetStore()

  describe '#storePath()', ->
    it 'should format path to storeit path', ->
      p = 'foo/bar'
      sp = userFile.storePath path.join(store, p)
      sp.should.equal "/#{p}"

  describe '#absolutePath()', ->
    it 'should storeit path resolve to absolute path', ->
      p = '/foo/bar'
      ap = userFile.absolutePath p
      ap.should.equal path.join(store, p)

  describe '#chunkPath()', ->
    it 'should resolve storeit path from ipfs hash', ->
      h = 'someHash'
      chp = userFile.chunkPath h
      chp.should.equal '/.storeit/' + h

  describe '#dirCreate()', ->
    it 'should create directories at store root', ->
      p = '/foo'
      userFile.dirCreate p
        .then ->
          test('-d', userFile.absolutePath p).should.be.true

    it 'should create sub directories if necessary', ->
      p = '/bar/subdirA/subdirB'
      userFile.dirCreate p
        .then -> test('-d', userFile.absolutePath p).should.be.true

  describe '#create()', ->
    it 'should create files at store root', ->
      p = '/foo'
      userFile.create p
        .then -> test('-f', userFile.absolutePath p).should.be.true
    it 'should create sub directories if necessary', ->
      p = '/bar/subdirA/file'
      userFile.create p
        .then -> test('-f', userFile.absolutePath p).should.be.true

  describe '#exists()', ->
    it 'should be fulfilled if file exists in user store', (done) ->
      p = '/foo'
      touch "#{store}/#{p}"
      userFile.exists(p).should.be.fulfilled.and.notify done
    it 'should be rejected if file does not exist in user store', (done) ->
      userFile.exists('/bar').should.be.rejected.and.notify done

  describe '#del()', ->
    it 'should delete files in user store', ->
      p = '/foo'
      touch "#{store}/foo"
      userFile.del p
        .then -> test('-e', userFile.absolutePath p).should.be.false
    it 'should delete directories in user store', ->
      p = '/foo'
      mkdir "#{store}/foo"
      userFile.del p
        .then -> test('-e', userFile.absolutePath p).should.be.false

  describe '#move()', ->
    it 'should rename a file in user store', ->
      src = '/foo'
      dst = '/bar'
      touch "#{store}/#{src}"
      txt = 'hello wolrd'
      fs.writeFileSync "#{store}/#{src}", txt
      userFile.move src, dst
        .then ->
          test('-e', "#{store}/#{src}").should.be.false
          fs.readFileSync("#{store}/#{dst}").toString().should.equal txt

  describe '#getHostedChunks()', ->
    it 'should resolve to a chunks hash array', ->
      hosted = ['azdaz', 'dsdqs', 'sqdsd']
      mkdir "#{store}/.storeit"
      touch "#{store}/.storeit/#{chunk}" for chunk in hosted
      userFile.getHostedChunks()
        .then (res) ->
          res.includes(chunk).should.be.true for chunk in hosted
          hosted.includes(chunk).should.be.true for chunk in res

  describe '#generateTree()', ->
    before (done) ->
      this.timeout 60000
      child = spawn 'ipfs', ['daemon']
      child.on 'error', (err) -> console.log 'error', err
      node = ipfs.createNode(recoUnit: 100)
      log.setLevel ''
      node.connect().then ->
        log.setLevel 'error'
        done()
    it 'should generate the file tree from user store\'s file', ->
      mkdir "#{store}/foo"
      touch "#{store}/bar"
      touch "#{store}/foo/foobar"
      fs.writeFileSync "#{store}/bar", 'bar'
      fs.writeFileSync "#{store}/foo/foobar", 'foobar'
      expected = fs.readFileSync './test/resources/generateTree.expected.json'
      userFile.generateTree()
        .then (res) -> res.should.eql JSON.parse(expected)

  describe '#clear()', ->
    beforeEach ->
      resetStore()
      touch "#{store}/foo"
      touch "#{store}/bar"
      mkdir "#{store}/foobar"
      touch "#{store}/foobar/foo"
      touch "#{store}/.foo"
    after -> resetStore()

    it 'should remove all files in user synchronized dir', ->
      userFile.clear()
        .then -> fs.readdirAsync store
        .then (files) -> files.length.should.equal 0
    it 'should keep chunks if specified as arg', ->
      mkdir "#{store}/.storeit"
      touch "#{store}/.storeit/chunkA"
      touch "#{store}/.storeit/chunkB"
      userFile.clear(true)
        .then -> fs.readdirAsync store
        .then (files) -> files.length.should.equal 1
