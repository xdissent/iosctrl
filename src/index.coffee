# Load the Simulator class.
Simulator = require './simulator'

# Export a convenience function to open a new simulator with a url.
module.exports = (url) -> new Simulator url

# Export the Simulator class.
module.exports.Simulator = Simulator