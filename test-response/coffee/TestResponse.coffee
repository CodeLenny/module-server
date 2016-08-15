$ = null

###
Client-side module for communicating with test infrastructure.
###
class TestResponse

  ###
  Sends data to respond to a test.
  @param {String} namespace the event to emit data to
  @param {Array<Anything>} args data to pass
  ###
  @emit: (namespace, args...) ->
    $.post "/testresponse/#{namespace}/", {args}

define ["jquery"], (jq) ->
  $ = jq
  TestResponse
