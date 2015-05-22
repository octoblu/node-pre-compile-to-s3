commander = require 'commander'
fs        = require 'fs-extra'
{exec}    = require 'child_process'
_         = require 'lodash'
colors    = require 'colors/safe'
os        = require 'os'
path      = require 'path'
zlib      = require 'zlib'
tar       = require 'tar'
fstream   = require 'fstream'
temp      = require 'temp'

class PreCompileCommand
  parseOptions: =>
    commander
      .option '-p, --path <path>', "Output path (defaults to build)"
      .option '--production', "npm install --production (default true)"
      .option '--silent', "No output from npm install (default false)"
      .usage '[options] <path/to/package.json>'
      .parse process.argv

    @packageFile = _.first(commander.args) || path.join(process.cwd(),'package.json')
    @buildPath = commander.path || path.join(process.cwd(),'build')
    try
      @packageJSON = require @packageFile
    catch error
      console.error "unable to open #{@packageFile}"
      console.error error
      process.exit(1)

    @productionOnly = commander.production? || true
    @silent = commander.silent || false
    @config = require('node-pre-compile-install/config')(@packageJSON,commander)

  run: =>
    @parseOptions()
    temp.track()
    origDir = __dirname
    temp.mkdir @config.name, (err, dirPath) =>
      fs.copySync @packageFile, path.join(dirPath, 'package.json')
      process.chdir dirPath
      npmOptions = []
      npmOptions.push "--production" if @productionOnly
      exec "npm install #{npmOptions.join(' ')}", (error, stdout, stderr) =>
        console.log('exec error: ' + error) unless error == null
        console.log('stdout: ' + stdout) unless @silent
        console.log('stderr: ' + stderr) unless @silent

        process.chdir origDir
        fs.mkdirpSync @buildPath
        destination = path.join @buildPath, @config.file
        console.log destination

        options =
          path: path.join(dirPath, 'node_modules')
          type: "Directory"

        fstream.Reader options
          .pipe tar.Pack()
          .pipe zlib.Gzip()
          .pipe fs.createWriteStream(destination)

(new PreCompileCommand()).run()
