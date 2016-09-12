chai = require "chai"
should = chai.should()

express = require "express"

ModuleTest = require "../lib/ModuleTest"
#ModuleTest = require "../src/ModuleTest"
#ModuleTest.DEBUG = yes

custom = new ModuleTest "ModuleTest Custom Connect Server Testing"
custom
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
