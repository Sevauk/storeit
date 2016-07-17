fs = require 'fs'
Watcher = (require '../build/watcher').default

STORE_PATH = './.storeit'

try
  fs.unlinkSync STORE_PATH
  fs.mkdirSync STORE_PATH
catch
  # pass

watch = new Watcher STORE_PATH

describe 'File Watcher', ->
  it 'should watch', ->
    
