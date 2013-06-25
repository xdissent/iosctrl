# # index.coffee

path = require 'path'
child_process = require 'child_process'

# The path to the `sim` module, depending on whether this module was included
# as javascript or coffeescript.
simPath = path.join __dirname, "sim#{path.extname __filename}"

# ## Simulator
class Simulator
  constructor: (url) ->
    @child = null
    @running = false
    @open url if url?

  launching: -> @child? and !@running

  # Open a url in the simulator. Does nothing if it's already running.
  open: (url) ->
    return false if @child
    @child = child_process.fork simPath, [url]
    @child.on 'message', (msg) =>
      @running = true if msg is 'started'
      if msg is 'ended'
        @running = false
        @child = null
    @

  # Close the simulator. Does nothing if it's not running.
  close: ->
    return false unless @child?
    @child.kill()
    @child = null
    @

# ## Exports

# Export a convenience function to open a new simulator with a url.
module.exports = (url) -> new Simulator url

# Export the Simulator class.
module.exports.Simulator = Simulator