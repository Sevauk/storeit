process.env.NODE_ENV = 'test'
global.Promise = require 'bluebird'
global.chai = require 'chai'
global.should = chai.should()
spies = require 'chai-spies'
require 'shelljs/global'
global.importDfl = (mod) -> (require "../../build/daemon/#{mod}").default
global.log = (require '../../lib/log').default

chai.use spies
log.setLevel 'error'
