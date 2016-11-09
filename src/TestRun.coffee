Deferred = require "./Deferred"
bodyParser = require "body-parser"
{it} = require "mocha"

###
Manages a single `it` block as part of a {ModuleTest}.
###
class TestRun

  # @property {Promise<Mocha>} resolves with a Mocha `it` instance once the `it` block starts
  started: null

  # @property {Promise} resolves once data is received
  post: null

  # @property {Promise} resolves once the test has completed
  done: null

  ###
  @param {Test} test attributes to configure this run
  ###
  constructor: (@test) ->
    @started = new Deferred()
    @post = new Deferred()
    @done = new Deferred()
    @it()

  ###
  Adds a route to a server, listening for data to test.
  @param {Connect} a [Connect](http://senchalabs.github.com/connect) server
  ###
  route: (router) ->
    router.post "/testresponse/#{@test.handler}/", bodyParser.urlencoded({extended: yes}), (req, res) =>
      req.body.args = req.body.args[0] if req.body.args.length is 1
      @post.resolve req.body.args
      res.send "OK"

  ###
  Creates a [Mocha](https://mochajs.org/) `it` block for this test.
  ###
  it: ->
    {test, started, post, done} = @
    it test.name, ->
      @timeout test.timeout
      started.resolve @
      post
        .then (data) ->
          test.cb data if test.cb
        .then =>
          return if @state is "failed" and @currentRetry() < @retries()
          done.resolve()

module.exports = TestRun
