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
