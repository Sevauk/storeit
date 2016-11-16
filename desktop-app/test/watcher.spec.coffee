require './lib/init'
settings = importDfl 'settings'
Watcher = importDfl 'watcher'
userFile = importDfl 'user-file'

ignores = userFile.storePath settings.getHostDir()
store = settings.getStoreDir()
notifier = ->
watcher = new Watcher store, ignores, (ev) -> notifier(ev)


# TODO - QUICKFIX
# Currently just bypasses first event
darwinManage = (handler) ->
  if process.platform is 'darwin'
    notifier = (ev) ->
      notifier = handler
  else
    notifier = handler

describe 'Watcher', ->

  beforeEach ->
    watcher.stop()
    rm '-rf', store
    mkdir store
    notifier = -> null

  describe '#start()', ->
    it 'should startup watcher', (done) ->
      notifier = -> done()
      watcher.start().then -> touch "#{store}/foo"
      return

  describe '#stop()', ->
    it 'should prevent watcher from emitting events', ->
      watcher.start()
        .then ->
          watcher.stop()
          notifier = should.fail
          userFile.create('bar')
        .then -> Promise.delay 50

  describe '#dispatch()', ->
    it 'should emit watch events with correct path', (done) ->
      p = 'bar'
      darwinManage (ev) ->
        ev.path.should.equal "/#{p}"
        done() if p is 'bar'

      watcher.start().then -> userFile.create p
      return

    it 'should not emit events on host dir', ->
      notifier = should.fail
      watcher.start()
        .then -> userFile.chunkCreate 'foo'
        .then -> Promise.delay 50

    it 'should emit FADD events on file creation', (done) ->
      notifier = (ev) ->
        ev.type.should.equal 'FADD'
        notifier = -> null # reset notifier to not call done twice on OS X
        done()
      watcher.start().then -> userFile.create 'foo'
      return

    it 'should emit FADD events on directory creation', (done) ->
      notifier = (ev) ->
        ev.type.should.equal 'FADD'
        notifier = -> null # reset notifier to not call done twice on OS X
        done()
      watcher.start().then -> userFile.dirCreate 'foo'
      return

    it 'should emit FDEL events on file deletion', (done) ->
      darwinManage (ev) ->
        ev.type.should.equal 'FDEL'
        done()

      userFile.create 'foo'
        .then -> watcher.start()
        .then -> userFile.del 'foo'
      return

    it 'should emit FDEL events on directory deletion', (done) ->
      darwinManage (ev) ->
        ev.type.should.equal 'FDEL'
        done()

      userFile.dirCreate 'foo'
        .then -> watcher.start()
        .then -> userFile.del 'foo'
      return

    it 'should emit FUPT events on file update', (done) ->
      darwinManage (ev) ->
        ev.type.should.equal 'FUPT'
        done()

      userFile.create 'foo'
        .then -> watcher.start()
        .then -> touch userFile.absolutePath 'foo'
      return

  describe '#ignore()', ->
    it 'should make a file path ignored by the watcher', ->
      notifier = should.fail
      watcher.start()
        .then -> userFile.create 'foo'

  describe '#unignore()', ->
    it 'should make a file path unignored by the watcher', (done) ->
      watcher.ignore '/foo'
      watcher.unignore '/foo'
      notifier = ->
        notifier = -> null # reset notifier to not call done twice on OS X
        done()
      watcher.start()
        .then -> userFile.create 'foo'
      return

  describe '#isIgnored()', ->
    it 'should tell wether some file is ignored by the watcher', ->
      watcher.ignore '/foo'
      watcher.unignore '/bar'
      watcher.isIgnored('/foo').should.be.true
      watcher.isIgnored('/bar').should.be.false
