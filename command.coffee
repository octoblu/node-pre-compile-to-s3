commander = require 'commander'
packageJSON = require './package.json'

class Command
  run: =>
    commander
      .version packageJSON.version
      .command 'precompile', 'precompile node_modules'
      .command 'install', 'install a package'
      .command 'upload', 'upload the compiled node_modules tarball'
      .parse process.argv

    unless commander.runningCommand
      commander.outputHelp()
      process.exit 1

(new Command()).run()
