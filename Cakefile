Promise = require "bluebird"

fs = Promise.promisifyAll require "fs-extra"

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

docs = (opts) ->
  Promise
    .resolve exec "$(npm bin)/codo --name 'ModuleServer' --title 'ModuleServer Documentation' --readme README.md ./src test-response/coffee/* - ModuleTest.md"
    .then (res) ->
      console.log res.stderr
      console.log res.stdout

task 'docs', 'Build documentation', (opts) ->
  docs opts
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
      process.exit code

task 'ready', "Ensure all files are ready before a git commit", (opts) ->
  build()
    .then -> docs()
    .then -> invoke "test"

task 'gh-pages', "Build Github Pages", (opts) ->
  exec "cd _gh-pages; git status --porcelain --untracked-files=no"
    .then (res) ->
      if (res.stderr and res.stderr isnt "") or (res.stdout and res.stdout isnt "")
        throw new Error "gh-pages directory not clean"
    .then -> docs opts
    .then ->
      fs.copyAsync "doc", "_gh-pages/doc"
    .then ->
      Promise.resolve exec "cd _gh-pages; git add .; git commit -m 'Added documentation.'; git push origin gh-pages"
    .then ({stderr, stdout}) ->
      console.log stderr if stderr
      console.log stdout if stdout
    .then ->
      exec "git status --porcelain --untracked-files=no --ignore-submodules=dirty"
    .then (res) ->
      if (res.stderr and res.stderr isnt "") or (res.stdout and res.stdout isnt "")
        throw new Error "gh-pages directory not clean"
    .then ->
      exec "git add _gh-pages; git commit -m 'Updated gh-pages.'"
    .catch (err) ->
      console.log "Error: #{err}"
