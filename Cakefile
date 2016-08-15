Promise = require "bluebird"

binPath = require("bin-path")(require)
path = require "path"

{exec} = require "child-process-promise"
{spawn} = require "child_process"

###
Launch a process via require("child_process").spawn
@return {child_process.spawn}
###
launch = (cmd, args..., opts) ->
  if typeof opts isnt "object"
    args.push opts
    opts = null
  spawn cmd, args, opts

###
Streams all output and errors from a spawned child process.
@param {child_process.spawn} spawned
@return {child_process.spawn}
###
stream = (spawned) ->
  spawned.stdout.pipe process.stdout
  spawned.stderr.pipe process.stderr
  spawned

###
@param {child_process.spawn} spawned
@return {Promise<Number>} the exit code after the process is finished, returned as a promise.
###
promisifySpawn = (spawned) ->
  new Promise (resolve, reject) ->
    spawned.on 'exit', (code, signal) ->
      reject code if code isnt 0
      resolve code

build = (opts) ->
  Promise.resolve exec "$(npm bin)/coffee --bare --map --compile --output lib/ src/"

task 'docs', 'Build documentation', (opts) ->
  Promise
    .resolve exec "$(npm bin)/codo --name 'ModuleServer' --title 'ModuleServer Documentation' --readme README.md ./src test-response/coffee/* - ModuleTest.md"
    .then (res) ->
      console.log res.stderr
      console.log res.stdout
    .error (err) ->
      console.log "Error while creating docs: #{err}"

task 'build', "Build distributable files", (opts) ->
  build()
    .then ->
      console.log "Compiled successfully."
    .error (err) ->
      console.log "Error while compiling: #{err}"

option '-e', '--extensive', 'Runs tests with more iterations'

task 'test', 'Run tests against ModuleServer', (opts) ->
  build(opts)
    .then ->
      process.env.FULLTEST = yes if opts.extensive
      process.env.PATH += ":" + path.dirname binPath("mocha").mocha
      promisifySpawn stream launch "mocha", '--colors', '--compilers', 'coffee:coffee-script/register', {env: process.env}
    .then (code) ->
      console.log "Mocha ran successfully!"
    .error (code) ->
      console.log "Mocha failed with code #{code}"
