{exec} = require 'child_process'
path   = require 'path'

_      = require 'lodash'
async  = require 'async'
s3     = require 's3'

class Command
  constructor: (packageName) ->
    @packageName = packageName
    @client = s3.createClient({
      s3Options:
        accessKeyId: process.env.S3_ACCESS_KEY_ID
        secretAccessKey: process.env.S3_SECRET_ACCESS_KEY
    })

  run: (callback=->) =>
    unless @packageName?
      return callback new Error('USAGE: node-pre-compile-to-s3 <npm-package-name>')
    {S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY, S3_BUCKET_NAME} = process.env
    unless _.all [S3_ACCESS_KEY_ID, S3_SECRET_ACCESS_KEY, S3_BUCKET_NAME]
      return callback new Error('S3 Credentials not present')

    async.waterfall [@installPackage, @precompile, @push], callback

  installPackage: (callback=->) =>
    cmd = "npm --prefix=. install #{@packageName}"
    exec cmd, (error) => callback error

  precompile: (callback=->) =>
    cmd = "npm run precompile --loglevel=silent"
    cwd = path.join '.', 'node_modules', @packageName
    exec cmd, {cwd: cwd}, callback

  push: (stdout, stderr, callback=->) =>
    localFile = _.trim stdout
    basename = path.basename localFile

    s3Params =
      localFile: localFile
      s3Params:
        Bucket: process.env.S3_BUCKET_NAME
        Key: "#{@packageName}/#{basename}"

    uploader = @client.uploadFile s3Params
    uploader.on 'error', callback
    uploader.on 'end', => callback()

command = new Command(process.argv[2..-1].join(''))
command.run (error) =>
  if error?
    console.error error
    process.exit 1
