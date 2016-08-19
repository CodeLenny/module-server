Promise = require "bluebird"

chai = require "chai"
should = chai.should()
chai.use require "chai-http"

express = require "express"
ModuleServer = require "../src/ModuleServer"

createModuleServer = ->
  app = express()
  server = new ModuleServer app, "/module/", "/modules/ModuleConfig.js"
  [app, server]

getPort = (min=49152, max=65535) -> Math.floor(Math.random() * (max - min + 1)) + min

describe "ModuleServer", ->

  it "has default module paths", ->
    app = express()
    server = new ModuleServer app
    server.modulePath.should.equal "/module/"
    server.configPath.should.equal "/modules/ModuleConfig.js"

  it "routes absolute paths correctly", ->
    absolutePath = "https://cdnjs.cloudflare.com/ajax/libs/moment.js/2.14.1/moment.min.js"
    [app, server] = createModuleServer()
    corrected = server.correctPaths "AbsolutePathsTest",
      moment: absolutePath
    corrected.moment = absolutePath

  it "routes paths to public files", ->
    [app, server] = createModuleServer()
    corrected = server.correctPaths "PublicPathsTest",
      helper: "$PUBLIC/helper.js"
    corrected.helper = "/module/PublicPathsTest/helper.js"

  it "routes paths to CoffeeScript files (with .coffee)", ->
    [app, server] = createModuleServer()
    corrected = server.correctPaths "CoffeeScriptPathsTest",
      helper: "$COFFEE/helper.coffee"
    corrected.helper = "/module/PublicPathsTest/helper.js"

  it "routes paths to CoffeeScript files (without .coffee)", ->
    [app, server] = createModuleServer()
    corrected = server.correctPaths "CoffeeScriptPathsTest",
      helper: "$COFFEE/helper"
    corrected.helper = "/module/PublicPathsTest/helper"

  it "loads a module from an NPM package", ->
    [app, server] = createModuleServer()
    server.load "Example", "@codelenny/module-server-examples"
    chai
      .request app
      .get "/module/Example/ModuleServerExample.js"
      .end (err, res) ->
        should.not.exist err
        res.should.have.status 200
        res.should.have.header "content-type", "application/javascript"
        res.body.should.include "\n"
    return

  it "loads a module from a subdirectory in an NPM package", ->
    [app, server] = createModuleServer()
    server.load "NoSub", "@codelenny/module-server-examples/no-submodule"
    chai
      .request app
      .get "/module/NoSub/NoSub.js"
      .end (err, res) ->
        should.not.exist err
        res.should.have.status 200
        res.should.have.header "content-type", "application/javascript"
        res.body.should.include "\n"
    return

  it "loads multiple modules", ->
    [app, server] = createModuleServer()
    server.load "Example", "@codelenny/module-server-examples"
    server.load "NoSub", "@codelenny/module-server-examples/no-submodule"
    agent = chai.request.agent app
    agent
      .get "/module/Example/ModuleServerExample.js"
      .end (err, res) ->
        throw err if err
        res.should.have.status 200
        res.should.have.header "content-type", "application/javascript"
        res.body.should.include "\n"
        agent.get "/module/NoSub/NoSub.js"
      .end (err, res) ->
        throw err if err
        res.should.have.status 200
        res.should.have.header "content-type", "application/javascript"
        res.body.should.include "\n"
    return
