Promise = require "bluebird"
Deferred = require "../lib/Deferred"
should = require("chai").should()

describe "Deferred", ->

  it "should resolve", (done) ->
    deferred = new Deferred()
    deferred.then ->
      done()
    setTimeout deferred.resolve, 10

  it "should use .join().any", ->
    one = new Deferred()
    two = new Deferred()
    join = Promise
      .join one, two
      .any (data, other) ->
        data.should.equal 1
        should.not.exist other
    setTimeout (-> one.resolve 1), 25
    setTimeout (-> two.resolve 2), 50
    Promise
      .join one, two, join
      .then ([one, two, join]) ->
        one.should.equal 1
        two.should.equal 2

  it "should work with .all().any", ->
    one = new Deferred()
    two = new Deferred()
    join = Promise
      .all [one, two]
      .any (data, other) ->
        data.should.equal 1
        should.not.exist other
    setTimeout (-> one.resolve 1), 25
    setTimeout (-> two.resolve 2), 50
    Promise
      .join one, two, join
      .then ([one, two, join]) ->
        one.should.equal 1
        two.should.equal 2
