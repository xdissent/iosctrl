$ = require 'NodObjC'
require './frameworks'
Session = require './session'

# A flag to indicate that the runloop should continue.
shouldKeepRunning = true

# Create an "autorelease" pool.
pool = $.NSAutoreleasePool('alloc') 'init'

# Create a session instance and set the URL.
session = Session('alloc')('init') 'autorelease'
session.ivar 'url', $ process.argv[2]

# Listen for `message` events from the parent process and process them.
process.on 'message', (msg) ->
  session 'stop' if msg is 'stop'
  shouldKeepRunning = false if msg is 'exit'

# The main runloop.
tick = ->
  # Dispatch any runloop events for a brief window.
  $.NSRunLoop('currentRunLoop') 'runMode', $.NSDefaultRunLoopMode, 'beforeDate',
    $.NSDate 'dateWithTimeIntervalSinceNow', 0.01

  if shouldKeepRunning
    # Run again.
    setImmediate tick
  else
    # Drain the pool and exit ourselves.
    pool 'drain'
    process.exit()

# Start the session and begin the runloop.
session 'start'
tick()