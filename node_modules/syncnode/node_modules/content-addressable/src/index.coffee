
computeHash = require 'sha1'

class ContentAddressable
  constructor: ({@store}) ->
  write: (data, cb) ->
    hash = computeHash data
    @store.write hash, data
    if cb then cb null, hash else hash
  read: (hash, cb) -> @store.read hash, cb
  writeAll: (data, cb) ->
    keyValues = ({key: computeHash(each), value: each} for each in data)
    hashs = (key for {key, value} in keyValues)
    @store.writeAll keyValues, -> if cb then cb null, hashs
    hashs
  readAll: (hashs, cb) ->
    if cb then @store.readAll hashs, cb
    else @store.readAll hashs

module.exports =
  Interface: ContentAddressable
  memory: -> new ContentAddressable store: require('pluggable-store').memory()
  fileSystem: (args...) -> new ContentAddressable store: require('pluggable-store').server.fileSystem(args...)