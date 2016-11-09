chai = require "chai"
should = chai.should()

express = require "express"

ModuleServer = require "../lib/ModuleServer"
ModuleTest = require "../lib/ModuleTest"
#ModuleTest.DEBUG = yes

class RetryTest extends ModuleTest
  ###
  Override Mocha's `describe` to add retries
  ###
  _runner: =>
    moduleTest = @
    runner = super()
    describe = (name, cb) =>
      runner name, ->
        @retries 1
        cb()

noRetry = new RetryTest "ModuleTest, custom Retry Logic, no retry"
noRetry
  .server ->
    _count = 0
    app = express()
    app.get "/", (req, res) -> res.send "#{++_count}"
    app
  .blade ""
  .coffee """
    require ["jquery", "TestResponse"], ($, TestResponse) ->
      $
        .get "/", (count) ->
          TestResponse.emit "count", count
    """
    .onit "gets a server-side response", "count", 5000, (count) ->
      count.should.equal "1"
    .run 4

counter = 0
retry = new RetryTest "ModuleTest, custom Retry Logic, 1 retry"
retry
  .server ->
    _count = 0
    app = express()
    app.get "/", (req, res) -> res.send "#{++_count}"
    app
  .blade ""
  .coffee """
    require ["jquery", "TestResponse"], ($, TestResponse) ->
      $
        .get "/", (count) ->
          TestResponse.emit "count", count
    """
    .onit "gets a server-side response", "count", 5000, (count) ->
      if ++counter % 2 is 1
        should.fail()
    .run 4
