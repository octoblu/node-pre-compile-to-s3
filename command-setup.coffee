
commander = require 'commander'
fs        = require 'fs-extra'
{exec}    = require 'child_process'
_         = require 'lodash'
path      = require 'path'

PRE_COMPILE_INSTALL = 'node-pre-compile-install'
PRE_COMPILE_INSTALL_EXEC = "node 'node_modules/#{PRE_COMPILE_INSTALL}/install.js'"

class SetupCommand
  parseOptions: =>
    commander
      .usage '[options] <path/to/package.json>'
      .parse process.argv

    @packagePath = _.first(commander.args) || process.cwd()
    @packageFile = path.join(@packagePath,'package.json')

  run: =>
    @parseOptions()

    process.chdir @packagePath
    cmd = "npm --prefix=. install --save #{PRE_COMPILE_INSTALL} 2>&1"
    exec cmd, (error, stdout) =>
      console.log('exec error: ' + error) unless error == null
      console.log stdout
      return if error

      @packageJSON = require @packageFile
      if @packageJSON.bundleDependencies
        @packageJSON.bundledDependencies = _.union(@packageJSON.bundleDependencies, @packageJSON.bundledDependencies || [])
        delete @packageJSON.bundleDependencies
      @packageJSON.bundledDependencies = _.union(@packageJSON.bundledDependencies || [], [PRE_COMPILE_INSTALL])
      if @packageJSON.scripts?.preinstall? && @packageJSON.scripts?.preinstall != PRE_COMPILE_INSTALL_EXEC
        console.log 'Preinstall script already defined, not overriding!'
      else
        @packageJSON.scripts.preinstall = PRE_COMPILE_INSTALL_EXEC
      fs.writeFileSync(@packageFile, JSON.stringify(@packageJSON,null,2))

(new SetupCommand()).run()
