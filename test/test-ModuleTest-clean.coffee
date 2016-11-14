chai = require "chai"
should = chai.should()

express = require "express"

ModuleServer = require "../lib/ModuleServer"
ModuleTest = require "../lib/ModuleTest"
#ModuleTest.DEBUG = yes

_count = 0
clean = new ModuleTest "ModuleTest with Clean Option"
clean
  .server ->
    app = express()
    app.get "/", (req, res) -> res.send "#{++_count}"
    app
  .blade ""
  .coffee """
    require ["jquery", "TestResponse"], ($, TestResponse) ->
      $
        .get "/"
        .then (count) ->
          TestResponse.emit "first", count
          $.get "/"
        .then (count) ->
          TestResponse.emit "second", count
    """
    .onit "gets the first response", "first", 7000, (one) ->
      one.should.equal "1"
    .onit "gets the second response", "second", 7000, (two) ->
      two.should.equal "4"
      _count = 0
    .run {count: 4, clean: yes}
