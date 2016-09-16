###
Contains details about a single test that can be run as part of a {ModuleTest}.
###
class TestDesc

  ###
  @param {String} name the name to give to [Mocha](https://mochajs.org/)'s `it`
  @param {String} handler the event that will be called by `TestResponse.emit`
  @param {Integer} timeout **Optional** changes [Mocha](https://mochajs.org/)'s timeout.  Defaults to 2000ms.
  @param {Function} cb called with the data given to `TestResponse.emit`, to provide chai testing.
  ###
  constructor: (@name, @handler, @timeout, @cb) ->

module.exports = TestDesc
