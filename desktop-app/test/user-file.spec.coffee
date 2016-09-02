require './lib/init'
userFile = importDfl 'user-file'
store = userFile.absolutePath()

fs = Promise.promisifyAll(require 'fs')

del = require 'del'

describe 'User File', ->

  beforeEach ->
    rm '-rf', store
    mkdir store

  describe '#clear()', ->
    it 'should remove all files in user synchronized dir', ->
      touch "#{store}/foo"
      touch "#{store}/bar"
      mkdir "#{store}/foobar"
      touch "#{store}/foobar/foo"
      touch "#{store}/.foo"
      userFile.clear()
        .then -> fs.readdirAsync store
        .then (files) -> files.length.should.equal 0
