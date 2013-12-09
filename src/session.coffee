$ = require 'NodObjC'
debug = require('debug') 'iosctrl:session'
require './frameworks'

# Create the Session ObjC class.
module.exports = Session = $.NSObject.extend 'Session'

# Add ivars to the Session class.
Session.addIvar 'session', '@'
Session.addIvar 'app', '@'
Session.addIvar 'sys', '@'
Session.addIvar 'env', '@'
Session.addIvar 'args', '@'
Session.addIvar 'err', '@'
Session.addIvar 'out', '@'
Session.addIvar 'family', '@'

# Add the `stop` method to the Session class.
Session.addMethod 'stop', 'v@:', (self) ->
  debug "stop"
  self.ivar('session') 'requestEndWithTimeout', 10

# Add the `start` method to the Session class.
Session.addMethod 'start', 'v@:', (self) ->
  debug "start"

  # Initialize variables for the simulator config.
  app = $.DTiPhoneSimulatorApplicationSpecifier 'specifierWithApplicationPath',
    self.ivar 'app'
  sys = self.ivar('sys') ? $.DTiPhoneSimulatorSystemRoot 'defaultRoot'
  env = self.ivar('env') ? $.NSMutableDictionary 'dictionary'
  args = self.ivar('args') ? $.NSMutableArray 'arrayWithCapacity', 0
  err = self.ivar('err') ? $ '/tmp/iosctrl.err'
  out = self.ivar('out') ? $ '/tmp/iosctrl.out'
  fam = $ if (self.ivar('family') ? '').toLowerCase() is 'ipad' then 2 else 1

  # Create the simulator configuration.
  config = $.DTiPhoneSimulatorSessionConfig('alloc')('init') 'autorelease'
  config 'setApplicationToSimulateOnStart', app
  config 'setSimulatedSystemRoot', sys
  config 'setSimulatedApplicationShouldWaitForDebugger', 0
  config 'setSimulatedApplicationLaunchArgs', args
  config 'setSimulatedApplicationLaunchEnvironment', env
  config 'setSimulatedApplicationStdErrPath', err
  config 'setSimulatedApplicationStdOutPath', out
  config 'setLocalizedClientName', $ 'iosctrl'
  config 'setSimulatedDeviceFamily', fam

  # Create the simulator session and attach a delegate instance.
  session = $.DTiPhoneSimulatorSession('alloc')('init') 'autorelease'
  session 'setDelegate', self
  self.ivar 'session', session

  # Start the simulator session.
  err = $.NSError.createPointer()
  if session 'requestStartWithConfig', config, 'timeout', 30, 'error', err.ref()
    debug 'start requested'
    process.send 'starting' if process.send
  else
    debug 'start request failed'
    process.send 'ended' if process.send
    
# Add the `started` callback method to the Session class.
Session.addMethod 'session:didStart:withError:', 'v@:@c@',
  (self, sel, sess, did, err) ->
    if did
      debug 'started'
      process.send 'started' if process.send
    else
      debug 'start did not start', err
      process.send 'ended' if process.send

# Add the `ended` callback method to the Session class.
Session.addMethod 'session:didEndWithError:', 'v@:@@', (self, sel, sess, err) ->
  debug 'ended', err
  process.send 'ended' if process.send

# Register the Session class with the ObjC bridge.
Session.register()
