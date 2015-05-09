commander = require 'commander'
fs        = require 'fs-extra'
{exec}    = require 'child_process'
_         = require 'lodash'
colors    = require 'colors/safe'
s3        = require 's3'
path      = require 'path'
os        = require 'os'

class UploadCommand
  parseOptions: =>
    commander
      .option '-b, --bucket <bucket>', "S3 bucket name"
      .option '-p, --package <package.json>', "Package JSON to read defaults from"
      .option '-k, --key <s3_key>', "S3 key or PRECOMPILE_S3_ACCESS_KEY_ID"
      .option '-s, --secret <s3_secret>', "S3 secret or PRECOMPILE_S3_SECRET_ACCESS_KEY"
      .option '-r, --remoteFolder <folder>', "S3 folder name (default is '/')"
      .usage '[options] filename-name'
      .parse process.argv


    @packageFile = commander.package || path.join(process.cwd(),'package.json');

    @filename = _.first commander.args
    try
      @packageJSON = require @packageFile
    catch error
      console.error('unable to open', @packageFile)

    unless @filename? || @packageJSON?
      console.error colors.red '\n  You must specify a package name.'
      commander.outputHelp()
      process.exit 1

    unless @filename?
      @filename = 'build/' + [
            @packageJSON.name
            @packageJSON.version
            os.platform()
            os.arch()
            'node-modules'
          ].join('-') + '.tar.gz'

    @s3_access_key_id = commander.key || process.env.PRECOMPILE_S3_ACCESS_KEY_ID
    @s3_secret_access_key = commander.secret || process.env.PRECOMPILE_S3_SECRET_ACCESS_KEY
    @s3_bucket = commander.bucket || 'octoblu-npm'
    @s3_folder = commander.remoteFolder

    unless @s3_folder?
      @s3_folder = "npm/#{@packageJSON.name}/#{@packageJSON.version}"

    unless @s3_access_key_id? && @s3_secret_access_key?
      console.error colors.red '\n S3 Credentials are required.'
      commander.outputHelp()
      process.exit 1

    unless @s3_bucket?
      console.error colors.red '\n S3 bucket is required.'
      commander.outputHelp()
      process.exit 1

  run: =>
    @parseOptions()
    origDir = __dirname

    client = s3.createClient
      s3Options:
        accessKeyId: @s3_access_key_id
        secretAccessKey: @s3_secret_access_key

    basename = path.basename @filename

    s3Params =
      localFile: @filename
      s3Params:
        Bucket: @s3_bucket
        Key: "#{@s3_folder}/#{basename}"

    uploader = client.uploadFile s3Params
    uploader.on 'error', (error) ->
      throw error if error?

    uploader.on 'end', =>
      process.exit 0

(new UploadCommand()).run()
