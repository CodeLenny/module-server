$ = null

###
Source file to test ModuleTest.
###
class ModuleTesting
  @SIMPLE: "THIS IS A SIMPLE TEST"
  constructor: (sel) ->
    $(sel).text "Inserted via jQuery."


define ["jquery"], (jq) ->
  $ = jq
  ModuleTesting
