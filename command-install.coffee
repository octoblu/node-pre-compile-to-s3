commander = require 'commander'
fs        = require 'fs-extra'
{exec}    = require 'child_process'
_         = require 'lodash'
colors    = require 'colors/safe'

TMP_INSTALL_DIR = '.node-pre-compile-install'

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
    installTempPath = "#{@installPath}/#{TMP_INSTALL_DIR}"
    fs.mkdirpSync installTempPath unless fs.existsSync installTempPath
    process.chdir installTempPath
    cmd = "npm --prefix=. install #{@packageName} 2>&1"
    exec cmd, (error, stdout) =>
      process.chdir '..'
      console.log('exec error: ' + error) unless error == null
      console.log stdout
      fs.move "#{TMP_INSTALL_DIR}/node_modules/#{@packageName}", @packageName, {}, ->
        fs.removeSync TMP_INSTALL_DIR

(new InstallCommand()).run()
