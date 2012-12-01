
computeHash = require 'sha1'

class ContentAddressable
  constructor: ({@store}) ->
  write: (data, cb) ->
    hash = computeHash data
    @store.write hash, data, (err) -> cb err, hash
  read: (hash, cb) -> @store.read hash, cb
  writeAll: (data, cb) ->
    keyValues = ({key: computeHash(each), value: each} for each in data)
    hashs = (key for {key, value} in keyValues)
    @store.writeAll keyValues, (err) -> cb err, hashs
  readAll: (hashs, cb) -> @store.readAll hashs, cb

ContentAddressable.memory = -> new ContentAddressable store: require('pluggable-store').memory()
ContentAddressable.fileSystem = (args...) -> new ContentAddressable store: require('pluggable-store').server.fileSystem(args...)
module.exports = ContentAddressable
