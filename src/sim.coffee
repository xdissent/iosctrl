# # sim.coffee

# ## IPC

# Listen for `message` events from the parent process and process them.
# Currently only accepts the `exit` message which will stop the main runloop
# and the child process itself.
process.on 'message', (msg) ->
  console.log 'Child got message: ' + msg
  $.NSApplication('sharedApplication') 'terminate', null if msg is 'exit'

# ## Objc Initialization

# Load NodObjC
$ = require 'NodObjC'

# Load all required frameworks.
$.framework 'AppKit'
$.framework 'Foundation'
$.framework '/Applications/Xcode.app/Contents/OtherFrameworks/DevToolsFoundation.framework'
$.framework '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/PrivateFrameworks/iPhoneSimulatorRemoteClient.framework'

# ## Simulator Session Delegate

# Create a class that sends a message when the simulator starts and ends.
Delegate = $.NSObject.extend 'XDiosctrlDelegate'
Delegate.addMethod 'session:didStart:withError:', 'v@:@c@', ->
  process.send 'started'
Delegate.addMethod 'session:didEndWithError:', 'v@:@@', ->
  process.send 'ended'
  $.NSApplication('sharedApplication') 'terminate', null
Delegate.register()

# ## Main Application

# Create an "autorelease" pool.
pool = $.NSAutoreleasePool('alloc') 'init'

# Initialize variables for the simulator config.
app = $.DTiPhoneSimulatorApplicationSpecifier 'specifierWithApplicationPath',
  $ '/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform//Developer/SDKs/iPhoneSimulator6.1.sdk/Applications/MobileSafari.app'
sysRoot = $.DTiPhoneSimulatorSystemRoot 'defaultRoot'
env = $.NSMutableDictionary 'dictionary'
args = $.NSMutableArray 'arrayWithCapacity', 2
args 'addObject', $ '-u'
args 'addObject', $ process.argv[2]

# Create the simulator configuration.
config = $.DTiPhoneSimulatorSessionConfig('alloc')('init') 'autorelease'
config 'setApplicationToSimulateOnStart', app
config 'setSimulatedSystemRoot', sysRoot
config 'setSimulatedApplicationShouldWaitForDebugger', 0
config 'setSimulatedApplicationLaunchArgs', args
config 'setSimulatedApplicationLaunchEnvironment', env
config 'setSimulatedApplicationStdErrPath', $ '/tmp/iosctrl.err'
config 'setSimulatedApplicationStdOutPath', $ '/tmp/iosctrl.err'
config 'setLocalizedClientName', $ 'iosctrl'
config 'setSimulatedDeviceFamily', $ 1

# Create the simulator session and attach a delegate instance.
session = $.DTiPhoneSimulatorSession('alloc')('init') 'autorelease'
session 'setDelegate', Delegate('alloc')('init') 'autorelease'

# Start the simulator session.
err = $.NSError.createPointer()
ret = session 'requestStartWithConfig', config, 'timeout', 30, 'error', err.ref()
if ret > 0 then console.log 'LAUNCHED' else console.log 'ERRORED'

# Run the main runloop, blocking forever.
$.NSRunLoop('mainRunLoop') 'run'
pool 'drain'