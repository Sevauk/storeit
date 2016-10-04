require './lib/init'
settings = importDfl 'settings'
store = settings.getStoreDir()
host = settings.getHostDir()
Watcher = importDfl 'watcher'
userFile = importDfl 'user-file'

manageFsEvent = null
ignores = [/\.storeit*/] # TODO proper ignore
watcher = new Watcher store, ignores, (args...) ->
  # console.log('event!')
  manageFsEvent args...

describe.only 'Watcher', ->

  beforeEach ->
    rm '-rf', store
    mkdir store
    manageFsEvent = ->

  describe '#watch()', ->
    before -> watcher.watch()

    it 'should trigger watch events with correct path', (done) ->
      p = 'bar'
      manageFsEvent = (ev) ->
        # console.log('done 1')
        ev.path.should.equal "/#{p}"
        done() if p is 'bar'
      touch "#{store}/#{p}"

    # FIXME
    # it 'should trigger FADD events on file creation', (done) ->
    #   manageFsEvent = (ev) ->
    #     ev.type.should.equal 'FADD'
    #     done()
    #   touch "#{store}/test"

    # TODO
    # it 'should trigger FADD events on directory creation', (done) ->
    # it 'should trigger FDEL events on file deletion', (done) ->
    # it 'should trigger FDEL events on directory deletion', (done) ->
    # it 'should trigger FUPT events on file update', (done) ->


  describe '#unwatch()', ->
    before ->
      watcher.watch()
      watcher.unwatch()
    it 'should prevent watcher to emit events', ->
      manageFsEvent = -> throw new Error 'watcher emited event'
      touch "#{store}/bar"
      Promise.delay(50)
