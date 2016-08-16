$ = null

###
Provides request.js locations for each module loaded via ModuleServer.

@example Loading ModuleConfig via RequireJS
  class MyModule
    ...
  requirejs ["/modules/ModuleConfig.js"], (ModuleConfig) ->
    new ModuleConfig ->
      define "MyModule", ["Dependency1", "Dependency2"], (dep1, dep2) -> MyModule

@example Fetching Blade configuration via RequireJS storage
  class SubModule
    ...
  define "SubModule", ["node-blade", "Dep1", "Dep2", "module"], (blade, dep1, dep2, module) ->
    blade.Runtime.options.mount = module.config().blade
    SubModule
###
class ModuleConfig

  # @property [Function] A function to call once the module configuration has been fully initialized.
  cb: null

  # @param [Function] cb A callback to run after the configuration has been initialized.
  constructor: (@cb) ->
    @fetchModules (modules) =>
      @parseModules modules, (config) =>
        @setConfig config, =>
          @cb()

  ###
  Fetches the module information from ModuleServer's output at /modules/.
  @param [Function] cb A callback to give the returned JSON.
  ###
  fetchModules: (cb) ->
    $.getJSON "/modules/", (data) =>
      cb data

  ###
  Parses the raw data from /modules/ (created by ModuleServer) into a format usable by Require.js
  @param [Object] modules The ModuleServer output
  @param [Function] cb Called with the generated configuration options
  ###
  parseModules: (modules, cb) ->
    config =
      config: {}
      shim:
        "socket.io": {exports: "io"}
        "blade": {exports: "blade"}
      paths:
        blade: "/blade/blade"
        jquery: "/jquery.js"
        moment: "https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.14.1/moment.min"
        livestamp: "https://cdn.rawgit.com/mattbradley/livestampjs/develop/livestamp"
        bluebird: "https://cdnjs.cloudflare.com/ajax/libs/bluebird/3.4.1/bluebird.min"
        "socket.io": "/socket.io/socket.io"
    for {name, main, paths} in modules
      config.paths[name] = main.replace /^(.*)\.js$/, "$1"
      console.log "## Loaded #{main} as #{name} ##"
      for own subpath, location of paths
        console.log "#{name}/#{subpath} points to #{location}"
        config.paths["#{name}/#{subpath}"] = location
      config.config[name] =
        public: "/module/#{name}/"
        blade: "/module/#{name}/blade/views/"
    cb config

  setConfig: (config, cb) ->
    requirejs.config config
    cb()

requirejs.config {paths: {jquery: "/jquery"}}

#define "ModuleConfig", ["/jquery.js"], (_$) ->
define ["jquery"], (jquery) ->
  $ = jquery
  ModuleConfig
