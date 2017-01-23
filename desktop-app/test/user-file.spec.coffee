require './lib/init'
userFile = importDfl 'user-file'
ipfs = (require '../build/daemon/ipfs')
settings = importDfl 'settings'
store = settings.getStoreDir()
host = settings.getHostDir()

{FileObj} = (require '../lib/protocol-objects')

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


  describe '#dirCreate()', ->
    it 'should create directories at store root', ->
      p = '/foo'
      userFile.dirCreate p
        .then -> test('-d', userFile.absolutePath p).should.be.true

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
    it 'should write the data in file', ->
      p = '/foo'
      data = 'foobar'
      userFile.create p, data
        .then -> fs.readFileAsync userFile.absolutePath(p), 'utf8'
        .should.eventually.equal data

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
        fs.readFileSync("#{store}/#{dst}", 'utf8').should.equal txt

  describe '#exists()', ->
    it 'should be fulfilled if file exists in user store', ->
      p = '/foo'
      touch "#{store}/#{p}"
      userFile.exists(p).should.be.fulfilled
    it 'should be rejected if file does not exist in user store', ->
      userFile.exists('/bar').should.be.rejected

  describe '#chunkPath()', ->
    it 'should resolve storeit path from ipfs hash', ->
      h = 'someHash'
      chp = userFile.chunkPath h
      chp.should.equal "#{userFile.storePath(host)}/#{h}"

  describe '#chunkCreate()', ->
    it 'should create a chunk in user host dir', ->
      h = 'someHash'
      data = 'foobar'
      userFile.chunkCreate h, data
        .then -> fs.readFileSync("#{host}/#{h}", 'utf8').should.equal data

  describe '#chunkDel()', ->
    it 'should delete chunks hosted by user', ->
      chunk = 'foo'
      userFile.chunkCreate chunk
        .then -> userFile.chunkDel chunk
        .then -> test('-e', "#{host}/#{chunk}").should.be.false

  describe '#getHostedChunks()', ->
    it 'should resolve to a chunks hash array', ->
      hosted = ['azdaz', 'dsdqs', 'sqdsd']
      mkdir "#{host}"
      touch "#{host}/#{chunk}" for chunk in hosted
      userFile.getHostedChunks()
        .then (res) ->
          res.includes(chunk).should.be.true for chunk in hosted
          hosted.includes(chunk).should.be.true for chunk in res

  describe '#generateTree()', ->
    it 'should generate the file tree from user store\'s file', ->
      mkdir "#{store}/foo"
      touch "#{store}/bar"
      touch "#{store}/foo/foobar"
      mkdir "#{store}/foo/barfoo"
      touch "#{store}/foo/barfoo/bar"
      fs.writeFileSync "#{store}/bar", 'bar'
      fs.writeFileSync "#{store}/foo/foobar", 'foobar'
      fs.writeFileSync "#{store}/foo/barfoo/bar", 'bar'
      expected = fs.readFileSync './test/resources/generateTree.expected.json'
      userFile.generateTree((p) -> "####{p}###")
        .should.eventually.eql JSON.parse(expected)

  # FIXME
  # describe '#getUnknownFiles()', ->
  #
  #   beforeEach ->
  #     touch "#{store}/foo"
  #     touch "#{store}/bar"
  #     mkdir "#{store}/foobar"
  #     touch "#{store}/foobar/bar"
  #
  #   it 'should resolve to the unknown files list', (done) ->
  #     files = {
  #       foo: new FileObj('/foo', true),
  #       foobar: new FileObj('/foobar', null)
  #     }
  #     dir = new FileObj('/', null, files)
  #     expected = ['/bar', '/foobar/bar']
  #     userFile.getUnknownFiles(dir)
  #       .should.eventually.eql expected
  #       .and.notify done

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
    it 'should preserve chunks if asked to', ->
      mkdir "#{host}"
      touch "#{host}/chunkA"
      touch "#{host}/chunkB"
      userFile.clear(true)
        .then -> fs.readdirAsync store
        .then (files) -> files.length.should.equal 1
