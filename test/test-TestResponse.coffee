chai = require "chai"
should = chai.should()

ModuleTest = require "../lib/ModuleTest"
#ModuleTest.DEBUG = yes

delayUntil = new ModuleTest "TestResponse.delayUntil"
delayUntil
  .blade "#text"
  .coffee """
    require ["jquery", "TestResponse"], ($, TestResponse) ->
      start = performance.now()
      console.log "Started at start"
      count = 0
      TestResponse
        .delayUntil 100, ->
          ++count
          $("#text").text() is "set"
        .then ->
          TestResponse.emit "change", $("#text").text(), count, performance.now() - start
      setTimeout (-> $("#text").text "set"), 1000
    """
  .onit "gets correct value", "change", 5000, ([val, checks, time]) ->
    should.exist val
    should.exist checks
    should.exist time
    val.should.equal "set"
    time.should.be.within 800, 1200
    checks.should.be.within 8, 12
  .run (if process.env.FULLTEST then 10 else 2)

time = new ModuleTest "TestResponse.time"
time
  .blade "#text"
  .coffee """
    require ["jquery", "TestResponse"], ($, TestResponse) ->
      TestResponse.time "automatic", 100, -> $("#text").text() is "set"
      TestResponse
        .time 100, -> $("#text").text() is "set"
        .then (time) ->
          TestResponse.emit "manual", time
      setTimeout (-> $("#text").text "set"), 1000
    """
  .onit "automatically emits", "automatic", 5000, (duration) ->
    should.exist duration
    duration.should.be.within 800, 1200
  .onit "resolves promise", "manual", 5000, (duration) ->
    should.exist duration
    duration.should.be.within 800, 1200
  .run (if process.env.FULLTEST then 10 else 2)
