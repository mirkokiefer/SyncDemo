
fs = require 'fs'
resolvePath = (require 'path').resolve
exec = require('child_process').exec

removeDir = (dir, cb) -> exec 'rm -r -f ' + dir, cb

class FileSystem
  constructor: (@rootPath) -> if not fs.existsSync @rootPath then fs.mkdirSync @rootPath
  write: (path, data, cb) -> fs.writeFile @path(path), data, 'utf8', cb
  read: (path, cb) -> fs.readFile @path(path), 'utf8', cb
  remove: (path, cb) -> fs.unlink @path(path), cb
  path: (fileName) -> resolvePath @rootPath, fileName
  delete: (cb) -> removeDir @rootPath, cb
  keys: (cb) -> fs.readdir @rootPath, cb

module.exports = FileSystem