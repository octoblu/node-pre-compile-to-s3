commander = require 'commander'
fs        = require 'fs-extra'
{exec}    = require 'child_process'
_         = require 'lodash'
colors    = require 'colors/safe'

class InstallCommand
  parseOptions: =>
    commander
      .option '-p, --path <path>', "Output path (defaults to current directory)"
      .usage '[options] package-name'
      .parse process.argv

    @packageName = _.first commander.args
    unless @packageName?
      console.error colors.red '\n  You must specify a package name.'
      commander.outputHelp()
      process.exit 1

    @installPath = commander.path || '.'

  run: =>
    @parseOptions()
    origDir = __dirname
    fs.mkdirpSync @installPath unless fs.existsSync @installPath
    process.chdir @installPath
    cmd = "npm --prefix=. install #{@packageName} 2>&1"
    exec cmd, (error, stdout) =>
      console.log('exec error: ' + error) unless error == null
      console.log stdout
      fs.move "node_modules/#{@packageName}", @packageName, {}, ->
        fs.removeSync "node_modules"
        process.chdir origDir

(new InstallCommand()).run()
