require './lib/init'

path = require 'path'

settings = importDfl 'settings'
storage = require 'node-persist'

describe 'Settings', ->

  beforeEach -> settings.clear()

  describe '#get()', ->
    it 'should return the current settings if no args passed', ->
      settings.get().should.eql settings.defaults
    it 'should return the current settings property passed as arg', ->
      settings.get('space').should.equal 2048

  describe '#setTokens()', ->
    it 'should set the auth property', ->
      params = {type: 'foo', tokens: 'bar'}
      settings.setTokens params.type, params.tokens
      settings.get('auth').should.eql params

  describe '#getAuthType()', ->
    it 'should return the auth type', ->
      type = 'facebook'
      settings.setTokens type, ''
      settings.getAuthType().should.equal type

  describe '#setTokens()', ->
    it 'should set the auth property', ->
      params = {type: 'foo', tokens: 'bar'}
      settings.setTokens params.type, params.tokens
      settings.get('auth').should.eql params

  describe '#getTokens()', ->
    it 'should return the auth tokens for the specified auth type', ->
      type = 'facebook'
      tokens = {access_token: 'foo', refresh_token: 'bar'}
      settings.setTokens type, tokens
      settings.getTokens(type).should.eql tokens
    it 'should return null if no type specified', ->
      settings.setTokens 'foo', {}
      should.equal(settings.getTokens(), null)

  describe '#resetTokens()', ->
    it 'should reset the auth settings', ->
      settings.setTokens 'facebook', {access_token: 'foo'}
      settings.resetTokens()
      settings.get('auth').should.eql {type: null, tokens: null}

  describe '#getStoreDir()', ->
    it 'should return the path to the user\'s synchronized folder', ->
      settings.getStoreDir().should.equal settings.get('folderPath')

  describe '#setStoreDir()', ->
    it 'should set the path to the user\'s synchronized folder', ->
      p = '/tmp/foo'
      settings.setStoreDir p
      settings.getStoreDir().should.equal path.resolve(p)

  describe '#getHostDir()', ->
    it 'should return the path to the user\'s hosting folder', ->
      p = '/tmp/foo'
      settings.setStoreDir p
      settings.getHostDir().should.equal path.join(p, '.storeit')

  describe '#getBandwidth()', ->
    it 'should return the user\'s max allocated bandwidth', ->
      settings.getBandwidth().should.equal settings.get('bandwidth')

  describe '#setBandwidth()', ->
    it 'should set the path to the user\'s synchronized folder', ->
      b = 42
      settings.setBandwidth b
      settings.getBandwidth().should.equal b

  describe '#save()', ->
    it 'should save user\'s configuration', ->
      settings.setStoreDir '/new/path'
      settings.setBandwidth 42
      settings.save()
      settings.get().should.eql storage.getItemSync 'user-settings'

  describe '#reload()', ->
    it 'should reload the saved configuration', ->
      p = '/saved/path'
      b = 42
      settings.setStoreDir p
      settings.setBandwidth b
      settings.save()
      settings.setStoreDir '/some/other/path'
      settings.setBandwidth -b
      settings.reload()
      settings.getStoreDir().should.equal p
      settings.getBandwidth().should.equal b

  describe '#reset()', ->
    it 'should clear all the configuration but auth', ->
      auth = {type: 'facebook', tokens: {access_token: 'foo'}}
      p = '/some/path'
      settings.setStoreDir p
      settings.setTokens auth.type, auth.tokens
      settings.save()
      settings.reset()
      settings.getStoreDir().should.not.equal p
      settings.getStoreDir().should.equal settings.defaults.folderPath

      settings.setStoreDir p
      settings.reload()
      settings.getStoreDir().should.not.equal p
      settings.getAuthType().should.equal auth.type
      settings.getTokens(auth.type).should.eql auth.tokens

  describe '#clear()', ->
    it 'should clear the current settings', ->
      settings.get().auth = {type: 'foo', tokens: 'bar'}
      settings.get().folderPath = '/foobar'
      settings.get().space = 0
      settings.get().bandwidth = 42
      settings.clear()
      settings.get().should.eql settings.defaults
