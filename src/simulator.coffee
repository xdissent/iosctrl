path = require 'path'
child_process = require 'child_process'
debug = require 'debug'

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
    @_child = child_process.fork simPath, [url]
    @_child.on 'exit', =>
      @debug 'exit'
      clearTimeout @_killTimeout if @_killTimeout?
      @_child = null
      @state = 'ready'
    @_child.on 'message', (msg) =>
      @debug "message: #{msg}"
      @state = 'open' if msg is 'started'
      @_child.send 'exit' if msg is 'ended'
    @

  close: ->
    throw new Error 'not open' if @state is 'ready'
    @debug 'close'
    if @_child?
      @state = 'closing'
      @_child.send 'stop'
      @_killLater()
    else
      @state = 'ready'
    @

  _killLater: ->
    return false if @_killTimeout?
    @_killTimeout = setTimeout =>
      @_killTimeout = null
      @debug 'force killing'
      @_child.kill()
    , 10000

module.exports = Simulator
