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
  .onit "sets window.mod", "window.mod", 5000, ([modType, is10]) ->
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
  #.chrome(0)

stressTest = new ModuleTest "ModuleTest Stress Testing"
stressTest
  .load "ModuleTesting", "#{__dirname}/test-moduletest"
  .blade "#output"
  .coffee """
    require ["jquery", "ModuleTesting", "TestResponse"], ($, ModuleTesting, TestResponse) ->
      window.mod = new ModuleTesting "#output"
      x = 0
      while x < 1000000
        Math.tan Math.atan Math.tan x
        x++
      window.setTimeout (-> TestResponse.emit "250ms", $("#output").text()), 250
      window.setTimeout (-> TestResponse.emit "800ms", $("#output").text()), 800
  """
  .onit "responds in 250ms", "250ms", 5000, (output) ->
    should.exist output
    output.should.equal "Inserted via jQuery."
  .onit "responds in 800ms", "800ms", 5000, (output) ->
    should.exist output
    output.should.equal "Inserted via jQuery."
  .run (if process.env.FULLTEST then 150 else 5)
