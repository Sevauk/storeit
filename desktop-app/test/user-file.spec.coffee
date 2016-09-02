require './lib/init'
userFile = importDfl 'user-file'
store = userFile.absolutePath()

path = require('path')
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


  describe '#clear()', ->
    beforeEach ->
      resetStore()
      touch "#{store}/foo"
      touch "#{store}/bar"
      mkdir "#{store}/foobar"
      touch "#{store}/foobar/foo"
      touch "#{store}/.foo"

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
