$ = require 'NodObjC'
require './frameworks'
Session = require './session'

# A flag to indicate that the runloop should continue.
shouldKeepRunning = true

# Create an "autorelease" pool.
pool = $.NSAutoreleasePool('alloc') 'init'

# Create a session instance and set the URL.
session = Session('alloc')('init') 'autorelease'

configure = (config) ->
  session.ivar 'app', $ config.app if config.app?
  session.ivar 'sys', $ config.sys if config.sys?
  if config.env?
    env = $.NSMutableDictionary 'dictionary'
    env 'setObject', $(k), 'forKey', $(v) for k, v of config.env
    session.ivar 'env', env
  if config.args?
    args = $.NSMutableArray 'arrayWithCapacity', config.args.length
    args 'addObject', $ v for v in config.args
    session.ivar 'args', args
  session.ivar 'err', $ config.err if config.err?
  session.ivar 'out', $ config.out if config.out?
  session.ivar 'family', $ config.family if config.family?

# Listen for `message` events from the parent process and process them.
process.on 'message', (msg) ->
  switch msg
    when 'stop'
      session 'stop'
    when 'exit'
      shouldKeepRunning = false
    else
      configure msg
      session 'start'

process.send 'init'

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

# Begin the runloop.
tick()