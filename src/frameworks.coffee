# The full path to Xcode.
xcodePath = '/Applications/Xcode.app'

# The list of frameworks to load.
frameworks = module.exports = [
  'Cocoa'
  "#{xcodePath}/Contents/OtherFrameworks/DevToolsFoundation.framework"
  "#{xcodePath}/Contents/Developer/Platforms/iPhoneSimulator.platform/" +
    'Developer/Library/PrivateFrameworks/iPhoneSimulatorRemoteClient.framework'
]

# Load each framework into NodObjC.
$ = require 'NodObjC'
$.framework fw for fw in frameworks