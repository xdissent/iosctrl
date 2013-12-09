path = require 'path'
child_process = require 'child_process'
debug = require 'debug'
Q = require 'q'

# The path to the `sim` module, depending on whether this module was included
# as javascript or coffeescript.

simPath = path.join __dirname, "sim#{path.extname __filename}"

class Simulator
  constructor: (@config={}) ->
    return new Simulator arguments... unless @ instanceof Simulator
    @debug 'new', @config
    @_child = null
    @state = 'stopped'

  debug: ->
    @_debug ?= debug 'iosctrl:simulator'
    @_debug arguments...

  start: ->
    throw new Error 'not stopped' unless @state is 'stopped'
    @debug 'start'
    @state = 'starting'
    deferred = Q.defer()
    @_child = child_process.fork simPath
    exit = =>
      @debug 'start rejected'
      deferred.reject 'exited'
      @_exit()
    message = (msg) =>
      switch msg
        when 'init'
          @_child.send @config
        when 'started'
          @_child.removeListener 'message', message
          @_child.removeListener 'exit', exit
          @_child.on 'message', @_message.bind @
          @_child.on 'exit', @_exit.bind @
          @debug 'start resolved'
          deferred.resolve true
      @_message msg
    @_child.on 'exit', exit
    @_child.on 'message', message
    deferred.promise

  _exit: ->
    @debug '_exit'
    clearTimeout @_killTimeout if @_killTimeout?
    @_child = null
    @state = 'stopped'

  _message: (msg) ->
    @debug "_message: #{msg}"
    @state = 'started' if msg is 'started'
    @_child.send 'exit' if msg is 'ended'

  stop: ->
    throw new Error 'not started' if @state is 'stopped'
    @debug 'stop'
    @state = 'stopping'
    return Q.fcall(=> @state = 'stopped') unless @_child?
    deferred = Q.defer()
    @_child.on 'exit', =>
      @debug 'stop resolved'
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
    , 20000

module.exports = Simulator
