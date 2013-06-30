$ = require 'NodObjC'
debug = require('debug') 'iosctrl:session'
require './frameworks'

# Create the Session ObjC class.
module.exports = Session = $.NSObject.extend 'Session'

# Add ivars to the Session class.
Session.addIvar 'url', '@'
Session.addIvar 'session', '@'

# Add the `stop` method to the Session class.
Session.addMethod 'stop', 'v@:', (self) ->
  debug "stop"
  self.ivar('session') 'requestEndWithTimeout', 30

# Add the `start` method to the Session class.
Session.addMethod 'start', 'v@:', (self) ->
  debug "start"

  # Initialize variables for the simulator config.
  app = $.DTiPhoneSimulatorApplicationSpecifier 'specifierWithApplicationPath',
    $ '/Applications/Xcode.app/Contents/Developer/Platforms/' +
      'iPhoneSimulator.platform//Developer/SDKs/iPhoneSimulator6.1.sdk/' +
      'Applications/MobileSafari.app'
  sysRoot = $.DTiPhoneSimulatorSystemRoot 'defaultRoot'
  env = $.NSMutableDictionary 'dictionary'
  args = $.NSMutableArray 'arrayWithCapacity', 2
  args 'addObject', $ '-u'
  args 'addObject', self.ivar 'url'

  # Create the simulator configuration.
  config = $.DTiPhoneSimulatorSessionConfig('alloc')('init') 'autorelease'
  config 'setApplicationToSimulateOnStart', app
  config 'setSimulatedSystemRoot', sysRoot
  config 'setSimulatedApplicationShouldWaitForDebugger', 0
  config 'setSimulatedApplicationLaunchArgs', args
  config 'setSimulatedApplicationLaunchEnvironment', env
  config 'setSimulatedApplicationStdErrPath', $ '/tmp/iosctrl.err'
  config 'setSimulatedApplicationStdOutPath', $ '/tmp/iosctrl.out'
  config 'setLocalizedClientName', $ 'iosctrl'
  config 'setSimulatedDeviceFamily', $ 1

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
Session.addMethod 'session:didStart:withError:', 'v@:@c@', (self, sel, did) ->
  if did
    debug 'started'
    process.send 'started' if process.send
  else
    debug 'start did not start'
    process.send 'ended' if process.send

# Add the `ended` callback method to the Session class.
Session.addMethod 'session:didEndWithError:', 'v@:@@', ->
  debug 'ended'
  process.send 'ended' if process.send

# Register the Session class with the ObjC bridge.
Session.register()
