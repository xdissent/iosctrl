path = require 'path'
child_process = require 'child_process'
debug = require 'debug'
Q = require 'q'

# The path to the `sim` module, depending on whether this module was included
# as javascript or coffeescript.

simPath = path.join __dirname, "sim#{path.extname __filename}"

class Simulator
  constructor: (url) ->
    @debug 'new'
    @_child = null
    @state = 'ready'
    @open url if url?

  debug: ->
    @_debug ?= debug 'iosctrl:simulator'
    @_debug arguments...

  open: (url) ->
    throw new Error 'not ready' unless @state is 'ready'
    @debug "open: #{url}"
    @state = 'opening'
    deferred = Q.defer()
    @_child = child_process.fork simPath, [url]
    exit = =>
      @debug 'open rejected'
      deferred.reject 'exited'
      @_exit()
    message = (msg) =>
      if msg is 'started'
        @_child.removeListener 'message', message
        @_child.removeListener 'exit', exit
        @_child.on 'message', @_message.bind @
        @_child.on 'exit', @_exit.bind @
        @debug 'open resolved'
        deferred.resolve true
      @_message msg
    @_child.on 'exit', exit
    @_child.on 'message', message
    deferred.promise

  _exit: ->
    @debug '_exit'
    clearTimeout @_killTimeout if @_killTimeout?
    @_child = null
    @state = 'ready'

  _message: (msg) ->
    @debug "_message: #{msg}"
    @state = 'open' if msg is 'started'
    @_child.send 'exit' if msg is 'ended'

  close: ->
    throw new Error 'not open' if @state is 'ready'
    @debug 'close'
    @state = 'closing'
    return Q.fcall(=> @state = 'ready') unless @_child?      
    deferred = Q.defer()
    @_child.on 'exit', =>
      @debug 'close resolved'
      deferred.resolve true
    @_child.send 'stop'
    @_killLater()
    deferred.promise

  _killLater: ->
    return false if @_killTimeout?
    @_killTimeout = setTimeout =>
      @_killTimeout = null
      @debug 'force killing'
      @_child.kill()
    , 30000

module.exports = Simulator
