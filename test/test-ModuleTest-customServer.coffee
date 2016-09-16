chai = require "chai"
should = chai.should()

express = require "express"

ModuleServer = require "../lib/ModuleServer"
ModuleTest = require "../lib/ModuleTest"
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

withModule = new ModuleTest "ModuleTest Custom Connect Server with own ModuleServer"
withModule
  .server ->
    app = express()
    moduleServer = new ModuleServer app, "/module/", "/modules/ModuleConfig.js"
    moduleServer.load "ModuleTesting", "#{__dirname}/test-moduletest"
    [app, moduleServer]
  .blade ""
  .coffee """
    require ["ModuleTesting", "TestResponse"], (ModuleTesting, TestResponse) ->
      str = ModuleTesting.SIMPLE
      TestResponse.emit "simple", str
    """
  .onit "gets a simple string", "simple", 5000, (str) ->
    should.exist str
    str.should.equal "THIS IS A SIMPLE TEST"
  .run (if process.env.FULLTEST then 5 else 2)
