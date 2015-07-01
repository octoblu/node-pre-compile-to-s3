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
path      = require 'path'

class CompressCommand
  parseOptions: =>
    commander
      .option '-o, --output <path>', "Output path (defaults to build)"
      .usage '[options] <path/to/package.json>'
      .parse process.argv

    @filename = _.first(commander.args) || path.join(process.cwd(),'package.json')
    @packageJSON = require @filename
    @packageDir = path.dirname @filename
    @outputDir = commander.output || path.join(@nodeModulesDir, '..')

  getFilename: =>
    [
      @packageJSON.name
      @packageJSON.version
      process.version
      os.platform()
      os.arch()
      'node-modules'
    ].join('-') + '.tar.gz'

  run: =>
    @parseOptions()
    process.chdir @packageDir
    filename = @getFilename()
    destination = path.join @outputDir, filename
    console.log destination

    options =
      path: path.join @packageDir, 'node_modules'
      type: "Directory"

    fstream.Reader options
      .pipe tar.Pack()
      .pipe zlib.Gzip()
      .pipe fs.createWriteStream(destination)

(new CompressCommand()).run()
