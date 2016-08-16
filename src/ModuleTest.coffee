net = require "net"
blade = require "blade"
coffee = require "coffee-script"
express = require "express"
bodyParser = require "body-parser"
phantom = require "phantom"
ModuleServer = require "./ModuleServer"
{describe, it, before, after} = require "mocha"
{exec} = require "child_process"

###
Picks random high ports in (hopefully) free teritory.
@param {Integer} min **Optional** the smalllest port to choose.  Defaults to `49152`.
@param {Integer} max **Optional** the largest port to choose.  Defaults to `65535`.
@param {Function} cb Called with the free port.
###
getPort = (min=49152, max=65535, cb) ->
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
    server.close()
    cb port if cb
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
  @property {Array<Function>} functions that will create an `it` test run.
  @private
  ###
  _it: null

  ###
  @property {Object<String, String>} module `name: path` to load via ModuleServer.
  ###
  _load: null

  ###
  Initializes a new testing environment for a series of tests (`it` blocks) inside a single
  `describe` block.
  @param {String} describeName a name to use for the `describe` block.
  ###
  constructor: (@describeName) ->
    @_load =
      TestResponse: "#{__dirname}/../test-response/"
    @_it = []

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
    if not cb
      cb = timeout
      timeout = 2000
    @_it.push (router, started) =>
      args = new Promise (resolve, reject) ->
        router.post "/testresponse/#{handler}/", bodyParser.urlencoded({extended: yes}), (req, res) ->
          console.log "Got #{req.body.args}" if ModuleTest.DEBUG
          resolve req.body.args
        started()
      it name, ->
        @timeout timeout
        args.then (args) ->
          cb args... if cb
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
        page.property 'onError', (msg) ->
          console.log "Page experienced error: #{msg}" if ModuleTest.DEBUG
        page.property 'onConsoleMessage', (msg) ->
          console.log "Page logged: #{msg}" if ModuleTest.DEBUG
        page.open "http://localhost:#{port}/"
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
              <script data-main="/test.js" src="/requirejs/"></script>
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
  Runs the given tests in a [Mocha](https://mochajs.org/) `describe` block the given number of times.
  @param {Integer} count **Optional** the number of times to run the tests.  Defaults to `1`.
  @return {ModuleTest}
  ###
  run: (count=1) ->
    for i in [1..count]
      do (i, count) =>
        getPort (port) =>
          [phantomInstance, phantomPage] = []
          name = if count is 1 then @describeName else "#{@describeName} (run #{i}/#{count})"
          describe name, =>
            router = express()
            router.get "/", @_index
            router.get "/test.js", @_testScript
            moduleServer = new ModuleServer router, "/module/", "/modules/ModuleConfig.js"
            moduleServer.load name, path for name, path of @_load
            ret = no
            server = router.listen port
            _started = 0
            onStart = =>
              if ++_started is @_it.length
                @startPhantom port
                  .then (res) ->
                    [phantomInstance, phantomPage] = res
            after =>
              server.close() if server
              phantomPage.close() if phantomPage?
              phantomInstance.exit() if phantomInstance?
            for _it in @_it
              _it router, onStart
    @

  ###
  Starts the testing server running via a Chrome browser for manual debugging.
  Creates a fake test to keep the server alive.
  @param {Integer} timeout **Optional** the delay length to ensure that the developer tools
    have opened, in ms.  Defaults to 10000 ms (10 seconds).
  @return {ModuleTest}
  ###
  chrome: (timeout=10000)->
    getPort (port) =>
      router = express()
      router.get "/", @_index
      router.get "/test.js", @_testScript
      moduleServer = new ModuleServer router, "/module/", "/modules/ModuleConfig.js"
      moduleServer.load name, path for name, path of @_load
      server = router.listen port
      exec "google-chrome http://localhost:#{port}/"
      describe "Developer Tools for #{@describeName}", ->
        it "Opens Developer Tools", (done) ->
          @timeout timeout + 500
          setTimeout done, timeout
    @

module.exports = ModuleTest
