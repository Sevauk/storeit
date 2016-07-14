(require 'chai').should()
require './watcher'

describe 'Sample test', ->
  it 'should make a stupid addition', ->
    num = 21 + 21
    num.should.equal 42
