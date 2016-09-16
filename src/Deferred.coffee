Bluebird = require("bluebird")
###
Creates a deferred Promise, that can be resolved in a later scope.
###
class Deferred extends Bluebird
  constructor: ->
    executor = (@resolve, @reject) => undefined
    @_bitField = 0
    @_fulfillmentHandler0 = undefined
    @_rejectionHandler0 = undefined
    @_promise0 = undefined
    @_receiver0 = undefined
    @_resolveFromExecutor(executor)
    @_promiseCreated()
    @_fireEvent("promiseCreated", this)

module.exports = Deferred
