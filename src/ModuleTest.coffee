Promise = require "bluebird"
net = require "net"
blade = require "blade"
coffee = require "coffee-script"
express = require "express"
bodyParser = require "body-parser"
phantom = require "phantom"
ModuleServer = require "./ModuleServer"
{describe, it, before, after} = require "mocha"
{exec} = require "child_process"
chalk = require "chalk"

TestDesc = require "./TestDesc"
TestRun = require "./TestRun"

###
Picks random high ports in (hopefully) free teritory.
@param {Integer} min **Optional** the smalllest port to choose.  Defaults to `49152`.
@param {Integer} max **Optional** the largest port to choose.  Defaults to `65535`.
@param {Function} cb Called with the free port.
###
getPort = (min=49152, max=65535, cb) ->
  new Promise (resolve, reject) ->
    if typeof max is "function"
      cb = max
      max = 65525
    if typeof min is "function"
      cb = min
      min = 49152
    port = Math.floor(Math.random() * (max - min + 1)) + min
    server = net.createServer()
    server.once 'error', (err) ->
      console.log "Port #{port} taken.  Retrying."
      getPort min, max, cb
    server.once 'listening', ->
      server.close ->
        cb port if cb
        resolve port
    server.listen port

###
Sets up a [Mocha](https://mochajs.org/) testing environment for server-side components.
###
class ModuleTest

  ###
  @property {Boolean} `true` to print more messages while running.
  ###
  @DEBUG: no

  ###
  @property {String} the name to give the `describe` block this test will create
  @private
  ###
  describeName: null

  ###
  @property {Promise<String>} elements inside the body of the testing webpage
  @private
  ###
  _body: null

  ###
  @property {Array<TestDesc>} tests to run
  @private
  ###
  _tests: null

  ###
  @property {Object<String, String>} module `name: path` to load via ModuleServer.
  ###
  _load: null

  ###
  @property {Function<Connect>} a function that returns a [Connect](http://senchalabs.github.com/connect) server.
  ###
  _server: null

  ###
  @property {Boolean} `true` to only run this test.
  ###
  _only: null

  ###
  @property {Boolean} `true` to skip this test.
  ###
  _skip: null

  ###
  @property {PhantomJS.Instance} A pointer to the PhantomJS instance.
  ###
  _phantomInstance: null

  ###
  @property {PhantomJS.Page} A pointer to the PhantomJS page.
  ###
  _phantomPage: null

  ###
  Initializes a new testing environment for a series of tests (`it` blocks) inside a single
  `describe` block.
  @param {String} describeName a name to use for the `describe` block.
  ###
  constructor: (@describeName) ->
    @_load =
      TestResponse: "#{__dirname}/../test-response/"
    @_tests = []

  ###
  Allows a custom Connect server to be used.  Must not be assigned a port.
  @property {Function<Connect>} _server a function to generate a new Connect server.  Can optionally return an array
    with both `Connect` and an existing `ModuleServer`.
  ###
  server: (@_server) -> @

  ###
  Passes load arguments to ModuleServer.
  @param {String} name module name to provide to the client
  @param {String} path location of module source files
  @see {ModuleServer.load}
  @return {ModuleTest}
  ###
  load: (name, path) ->
    @_load[name] = path
    @

  ###
  Determines the elements to include inside the body of the testing webpage.
  @param {String} str [blade](https://github.com/bminer/node-blade) formatted text to include
  @return {ModuleServer}
  ###
  blade: (str) ->
    if not str or str is ""
      @_body = Promise.resolve("")
      return @
    @_body = new Promise (resolve, reject) ->
      blade.compile str, (err, tmpl) ->
        reject err if err
        tmpl {}, (err, html) ->
          reject err if err
          resolve html
    @

  ###
  Determines the elements to include inside the body of the testing webpage.
  @param {String} str HTML elements to include
  @return {ModuleTest}
  ###
  html: (str) ->
    @_body = str
    @

  ###
  Determines [RequireJS](http://requirejs.org/)-based code to run tests.
  @param {String} src [CoffeeScript](http://coffeescript.org/) formatted source to use
  @return {ModuleTest}
  ###
  coffee: (src) ->
    @_js = coffee.compile src, {bare: yes}
    @

  ###
  Determines [RequireJS](http://requirejs.org/)-based code to run tests.
  @param {String} src JavaScript formatted source to use
  @return {ModuleTest}
  ###
  js: (src) ->
    @_js = src

  ###
  Provides a test that will be triggered by client calls to `TestResponse.emit`.
  @param {String} name the name to give to [Mocha](https://mochajs.org/)'s `it`
  @param {String} handler the event that will be called by `TestResponse.emit`
  @param {Integer} timeout **Optional** changes [Mocha](https://mochajs.org/)'s timeout.  Defaults to 2000ms.
  @param {Function} cb called with the data given to `TestResponse.emit`, to provide chai testing.
  @return {ModuleTest}
  ###
  onit: (name, handler, timeout, cb) ->
    @_tests.push new TestDesc name, handler, timeout, cb
    @

  ###
  Listens to a handler.  Returns an object containing a method to define tests.
  @param {String} Handler
  @return {ModuleTest}
  @example Define a test
    test
      .on("divCount")
      .it "has 10 divs", 5000, (divCount) -> divCount.should.equal 10
  ###
  on: (handler) ->
    res = {}
    res.it = (name, timeout, cb) =>
      @onit name, handler, timeout, cb
      return @

  ###
  Only run this ModuleTest.  Uses `describe.only(...)` in Mocha.
  @return {ModuleTest}
  ###
  only: ->
    @_only = yes
    @

  ###
  Skip this ModuleTest.  Uses `describe.skip(...)` in Mocha.
  @return {ModuleTest}
  ###
  skip: ->
    @_skip = yes
    @

  ###
  Starts a [Phantom](https://github.com/amir20/phantomjs-node) browser, and visits the index
  page at the server given.
  @param {Integer} port the port a server is listening on
  @return {Promise<Array<Phantom.create(), Phantom.create().open()>>}
  @private
  ###
  startPhantom: (port) ->
    page = null
    instance = null
    phantom
      .create()
      .then (i) ->
        instance = i
        instance.createPage()
      .then (p) ->
        page = p
        page.on 'onError', (err) ->
          return unless ModuleTest.DEBUG
          console.log chalk.red.bold "Page experienced error"
          console.log err
          console.log "\n"
        page.on 'onConsoleMessage', (msg) ->
          return unless ModuleTest.DEBUG
          console.log chalk.blue.bold "Page Logged:"
          console.log chalk.dim.blue "  " + msg.replace("\n", "  \n")
        page.open "http://localhost:#{port}/codelenny-module-server/"
      .then (content) ->
        console.log content if ModuleTest.DEBUG
      .catch (err) ->
        console.log "Error: #{err}"
      .then ->
        [instance, page]

  ###
  Express route to fetch the index page for a server.
  @param {Express.req} req details about the request
  @param {Express.res} res our response to the user
  @private
  ###
  _index: (req, res) =>
    if not @_body
      @_body = ""
      return console.log "No HTML given, defaulting to an empty body"
    Promise
      .resolve @_body
      .then (body) ->
        res.send """
          <!DOCTYPE html>
          <html>
            <body>
              #{body}
              <script data-main="/codelenny-module-server/test.js" src="/requirejs/"></script>
            </body>
          </html>
        """
      .catch (err) ->
        console.log "Error resolving body: #{err}"

  ###
  Express route to fetch the [RequireJS](http://requirejs.org/)-based test runner.
  @param {Express.req} req details about the request
  @param {Express.res} res our response to the user
  @private
  ###
  _testScript: (req, res) =>
    if not @_js
      res.send ""
      return console.log "No JavaScript!"
    res.send """
      define("clienttest", function(require) {
        #{@_js}
      });
      define(["/modules/ModuleConfig.js"], function (ModuleConfig) {
        new ModuleConfig(function() {
          require(["clienttest"], function(clienttest) {});
        });
      });
      """

  ###
  Express route to fetch the [RequireJS](http://requirejs.org/)-based test runner,
  and listen for the close event at the same time.
  @param {Express.req} req details about the request
  @param {Express.res} res our response to the user
  @private
  ###
  _listenCloseTestScript: (req, res) =>
    if not @_js
      res.send ""
      return console.log "No JavaScript!"
    res.send """
      define("clienttest", function(require) {
        #{@_js}
        $jq = require("jquery");
        $jq(window).on("unload", function() {
          $jq.ajaxSetup({async: false});
          $jq.get("/moduletest/unload/");
        });
      });
      define(["/modules/ModuleConfig.js"], function (ModuleConfig) {
        new ModuleConfig(function() {
          require(["clienttest"], function(clienttest) {});
        });
      });
    """

  ###
  Creates a [Connect](http://senchalabs.github.com/connect) server, using {ModuleTest#_server} if avalible, otherwise
  creating a new Express server.  Provides basic routing for tests, and loads the required modules.
  ###
  _createServer: ->
    router = if @_server then @_server() else express()
    [router, moduleServer] = router if Array.isArray router
    router.get "/codelenny-module-server/", @_index
    router.get "/codelenny-module-server/test.js", @_testScript
    moduleServer ?= new ModuleServer router, "/module/", "/modules/ModuleConfig.js"
    moduleServer.load name, path for name, path of @_load
    moduleServer.finalize()
    router

  ###
  Returns the correct `describe`/`describe.only`/`describe.skip` depending on user input.
  Also allows adding hooks.
  @return {Mocha.describe}
  ###
  _runner: ->
    runner = describe
    if @_only
      runner = describe.only
    else if @_skip
      runner = describe.skip
    runner

  ###
  Runs the given tests in a [Mocha](https://mochajs.org/) `describe` block the given number of times.
  @param {Integer} count **Optional** the number of times to run the tests.  Defaults to `1`.
  @return {ModuleTest}
  ###
  run: (count=1) ->
    for i in [1..count]
      do (i, count) =>
        name = if count is 1 then @describeName else "#{@describeName} (run #{i}/#{count})"
        @_runner() name, =>
          [server, phantomInstance, phantomPage] = []
          tests = (new TestRun test for test in @_tests)

          started = (test.started for test in tests)
          done = (test.done.reflect() for test in tests)

          # Once a single `it` block has started to execute, start the server and a Phantom instance
          Promise
            .any started
            .then (test) ->
              # This test will be delayed as we're starting the server, so don't mark the test slow unless it takes
              # longer than 1.5 seconds.
              test.timeout test.timeout() + 1500
              test.slow 1500
            .then -> getPort()
            .then (port) =>
              router = @_createServer()
              Promise
                .map tests, (test) -> test.route router
                .then -> [port, router]
            .then ([port, router]) =>
              server = router.listen port
              @startPhantom port
            .then (res) =>
              [phantomInstance, phantomPage] = res
              @_phantomInstance = phantomInstance
              @_phantomPage = phantomPage
            .catch (err) ->
              console.log "Error starting tests for #{name}: #{err}"

          # Once all of the tests have fully finished, tear down the server and Phantom
          Promise
            .all done
            .then =>
              phantomPage.close() if phantomPage
              phantomInstance.exit() if phantomInstance
              return unless server
              new Promise (resolve, reject) -> server.close resolve
            .catch (err) ->
              console.log "Error tearing down after #{name}"
              throw err
    @

  ###
  Starts the testing server running via a Chrome browser for manual debugging.
  Creates a fake test to keep the server alive.
  @param {Integer} timeout **Optional** the delay length to ensure that the developer tools
    have opened, in ms.  If 0, listens for page close instead.  Defaults to 10000 ms (10 seconds).
  @return {ModuleTest}
  ###
  chrome: (timeout=10000)->
    getPort (port) =>
      router = if @_server then @_server() else express()
      [router, moduleServer] = router if Array.isArray router
      router.get "/codelenny-module-server/", @_index
      closed = null
      if timeout is 0
        closed = new Promise (resolve, reject) =>
          _timer = null
          open = (req, res, next) ->
            clearTimeout _timer
            next()
          close = (req, res) ->
            _timer = setTimeout resolve, 2000
            res.send ""
          router.get "/codelenny-module-server/test.js", open, @_listenCloseTestScript
          router.get "/moduletest/unload/", close
      else
        router.get "/codelenny-module-server/test.js", @_testScript
      moduleServer ?= new ModuleServer router, "/module/", "/modules/ModuleConfig.js"
      moduleServer.load name, path for name, path of @_load
      moduleServer.finalize()
      server = router.listen port
      cmd = "google-chrome http://localhost:#{port}/codelenny-module-server/"
      exec cmd
      console.log cmd if ModuleTest.DEBUG
      describe "Developer Tools for #{@describeName}", ->
        it "Opens Developer Tools", (done) ->
          if timeout is 0
            @timeout 0
            closed.then done
            yes
          else
            @timeout timeout + 500
            setTimeout done, timeout
    @

module.exports = ModuleTest
