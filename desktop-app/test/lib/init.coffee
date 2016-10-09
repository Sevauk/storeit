process.env.NODE_ENV = 'test'
global.Promise = require 'bluebird'

global.chai = require 'chai'
global.should = chai.should()
chaiAsPromised  = require 'chai-as-promised'
spies = require 'chai-spies'
chai.use spies
chai.use chaiAsPromised

path = require 'path'

require 'shelljs/global'
global.importDfl = (mod) -> (require "../../build/daemon/#{mod}").default

logger = (require '../../lib/log')
global.log = logger.default
logger.logToFile path.resolve 'test/log/error_log'
