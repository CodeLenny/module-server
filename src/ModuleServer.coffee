Express = require "express"
Blade = require "blade"
Coffee = require "coffee-middleware"

###
Connect plugin to serve modules.
###
class ModuleServer

  ###
  @property {Object} Stores modules that have been loaded as `{name, main, paths}`, where
  `name` is the client-side module name defined, `main` is a client-side path to the main script,
  and `paths` is an object of `{script: location}` of additional files to serve.
  ###
  _loadedPackages: []

  ###
  @param {Connect} router a [connect framework](https://github.com/senchalabs/connect) instance
  @param {String} modulePath a path to serve module files from.  Defaults to `/module/`
  @param {String} configPath a path to serve the module configuration from.
    Defaults to `/modules/ModuleConfig.coffee`
  ###
  constructor: (@router, @modulePath="/module/", @configPath="/modules/ModuleConfig.js") ->
    @list()
    @moduleConfig()
    @blade()
    @requirejs()
    @jquery()

  ###
  Loads a client module, and serves it under the provided name.

  Valid paths:

  | Type                      | Example                                                           |
  | ------------------------- | ----------------------------------------------------------------- |
  | Absolute path:            | `load("ServerConnection", "/usr/local/serverconnection/client/")` |
  | NPM package:              | `load("URLParser", "@codelenny/url-parser")`                      |
  | Directory in NPM package: | `load("QueryParser", "@codelenny/url-parser/query")`              |
  | Relative path:            | `load("Logging", "../../advanced-logging/")`                      |

  @param {String} name module name to provide to the client
  @param {String} path location of module source files
  ###
  load: (name, path) ->
    path = @findPath path
    pkg = require "#{path}/package.json"
    main = pkg.main
      .replace(/^coffee\/(.*)\.coffee/, "$1.js")
      .replace(/^public\/(.*)$/, "$1")
    @middleware name, path
    paths = @correctPaths name, pkg["com.codelenny.paths"]
    @_loadedPackages.push {name, main, paths}
    @loadSubmodules pkg, path

  ###
  Finds any submodules required by a given module.
  @param {Object} pkg the parsed contents of `package.json`
  @param {String} path location of module source files
  ###
  loadSubmodules: (pkg, path) ->
    pkgs = pkg["com.codelenny.client_module"] ? pkg["com.codelenny.client_modules"]
    return if not pkgs
    for name, subpath of pkgs
      @load name, require("path").resolve(path, subpath.replace "$PATH", path)

  ###
  Add middleware for a given module.
  @param {String} name module name to provide to the client
  @param {String} path location of module source files
  ###
  middleware: (name, path) ->
    @router.use "#{@modulePath}#{name}", Express.static "#{path}/public"
    @router.use "#{@modulePath}#{name}/blade", Blade.middleware "#{path}/blade"
    @router.use "#{@modulePath}#{name}", Coffee {src: "#{path}/coffee", compress: yes, encodeSrc: no}

  ###
  Modules can define paths to files under package.json that will be provided to RequireJS.
  Substitute locations to public files via `$PUBLIC`, and remove trailing `.js` extensions.

  For example, to provide a local copy of a library, `underscore.js` located in the public directory
  of a module loaded via `load("UserCounter", "@codelenny/user-counter")`:

  ```js
  // in package.json
  {
    ...,
    "com.codelenny.paths": {
      "_": "$PUBLIC/underscore",
      "jquery": "https://cdnjs.cloudflare.com/ajax/libs/jquery/3.1.0/core.js"
    }
  }
  ```

  ```js
  define(["UserCounter/_", "UserCounter/jquery"], function(_, $) {
    // _ and $ can be used
  });
  ```

  @param {String} name module name to provide to the client
  @param {Object<String, String>} paths an object of url locations to serve, and locations of files
  ###
  correctPaths: (name, paths) ->
    for script, location of paths
      paths[script] = location.replace("$PUBLIC", "#{@modulePath}#{name}").replace(/\.js$/, '')
    paths

  ###
  Locates a node module via `require.resolve`, then stripping the class.
  See {ModuleServer.load} for example paths.
  @param {String} path either an absolute file path, or a path to resolve.
  @return {String} a full path to the module required.
  ###
  findPath: (path) ->
    try if path[0] isnt "/"
      path = require
        .resolve path
        .replace new RegExp("^(.*\\/node_modules\\/#{path}).*$"), '$1'
    path

  ###
  Lists all loaded modules with paths to locate files.
  ###
  list: ->
    @router.get "/modules/", (req, res) =>
      fullPaths = @_loadedPackages.map ({name, main, paths}) => {name, main: "#{@modulePath}#{name}/#{main}", paths}
      res.json fullPaths

  ###
  Provides a configuration package (setup for RequireJS) at /modules/ModuleConfig.js
  @see ModuleConfig
  ###
  moduleConfig: ->
    @router.get @configPath, (req, res) =>
      res.sendFile require("path").resolve "#{__dirname}/../lib/ModuleConfig.js"

  ###
  Provides an empty Blade middleware to allow loading /blade/plugins/liveui.js
  ###
  blade: ->
    @router.use require("blade").middleware "#{__dirname}/../blade"

  ###
  Provides RequireJS source as /requirejs/
  ###
  requirejs: ->
    @router.get "/requirejs/", (req, res) ->
      res.sendFile require.resolve "requirejs/require.js"

  ###
  Provides jQuery source as /jquery.js
  ###
  jquery: ->
    @router.get "/jquery.js", (req, res) ->
      res.sendFile require.resolve "jquery/dist/jquery.min.js"

module.exports = ModuleServer
