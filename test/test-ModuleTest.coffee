chai = require "chai"
should = chai.should()

ModuleTest = require "../lib/ModuleTest"
#ModuleTest = require "../src/ModuleTest"
ModuleTest.DEBUG = no

simple = new ModuleTest "Simple Test of ModuleTest"
simple
  .load "ModuleTesting", "#{__dirname}/test-moduletest"
  .blade ""
  .coffee """
    require ["ModuleTesting", "TestResponse"], (ModuleTesting, TestResponse) ->
      str = ModuleTesting.SIMPLE
      TestResponse.emit "simple", str
    """
  .onit "gets simple response", "simple", 5000, (str) ->
    should.exist str
    str.should.equal "THIS IS A SIMPLE TEST"
  .run (if process.env.FULLTEST then 20 else 2)

outTest = new ModuleTest "HTML Output Checking with ModuleTest"
outTest
  .load "ModuleTesting", "#{__dirname}/test-moduletest"
  .blade "#output"
  .coffee """
    require ["jquery", "ModuleTesting", "TestResponse"], ($, ModuleTesting, TestResponse) ->
      window.mod = new ModuleTesting "#output"
      TestResponse.emit "window.mod", typeof window.mod, 10
      TestResponse.emit "random", 5
      window.setTimeout (-> TestResponse.emit "output", $("#output").text()), 500
  """
  .onit "sets window.mod", "window.mod", 5000, (modType, is10) ->
    should.exist modType
    should.exist is10
    modType.should.equal "object"
    parseInt(is10).should.equal 10
  .onit "gives a random response", "random", 5000, (output) ->
    parseInt(output).should.equal 5
  .onit "sets output text", "output", 5000, (output) ->
    should.exist output
    output.should.equal "Inserted via jQuery."
  .run (if process.env.FULLTEST then 20 else 2)
  .chrome(0)
