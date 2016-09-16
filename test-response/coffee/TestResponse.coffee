[$, Promise] = []

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

  ###
  Delays until some test is true.  Currently uses polling.
  @param {Integer} poll **Optional** how often the test should be checked, in milliseconds.  Defaults to `25`ms.
  @param {Function<Boolean>} test function to determine if progress should continue.  Resolves the promise as soon as
    the test returns `true`.
  @return {Promise} Resolves after the test returns `true`.
  ###
  @delayUntil: (poll=25, test) ->
    [poll, test] = [25, poll] if typeof poll is "function"
    new Promise (resolve, reject) ->
      timer = null
      doTest = ->
        return unless test()
        clearInterval timer
        resolve()
      timer = setInterval doTest, poll

  ###
  Times the duration until a function returns `true`.
  @overload time(namespace, poll, fn)
    Emits the duration (in ms) it took until `fn` returned `true` at the given namespace.
    @see TestResponse.emit
    @param {String} namespace the event to emit data to
    @param {Integer} poll **Optional** how often the test should be checked, in milliseconds.  Defaults to `25`ms.
    @param {Function<Boolean>} fn the function to test until it returns true
    @return {Promise<Number>} the duration (in ms) it took until `fn` returned true

  @overload time(poll, fn)
    Returns a promise that resolves with the duration it took until `fn` returned `true`.
    @param {Integer} poll **Optional** how often the test should be checked, in milliseconds.  Defaults to `25`ms.
    @param {Function<Boolean>} fn the function to test until it returns true
    @return {Promise<Number>} the duration (in ms) it took until `fn` returned true
  ###
  @time: (namespace, poll, test) ->
    if typeof namespace is "number"
      [namespace, poll, test] = [null, namespace, poll]
    else if typeof namespace is "function"
      [namespace, poll, test] = [null, 25, namespace]
    else if typeof poll is "function"
      [poll, test] = [25, poll]
    return unless typeof test is "function"
    new Promise (resolve, reject) ->
      timer = null
      start = performance.now()
      doTest = ->
        return unless test()
        duration = performance.now() - start
        clearInterval timer
        TestResponse.emit namespace, duration
        resolve duration
      timer = setInterval doTest, poll

define ["jquery", "bluebird"], (jq, bluebird) ->
  [$, Promise] = [jq, bluebird]
  TestResponse
