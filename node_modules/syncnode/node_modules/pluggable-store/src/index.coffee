
async = require 'async'

class PluggableStore extends require('eventemitter2').EventEmitter2
  constructor: ({@adapter}) ->
  exists: (cb) -> @adapter.exists cb
  create: (cb) -> @adapter.create cb
  destroy: (cb) -> @adapter.destroy cb
  ensureExists: (cb) ->
    obj = this
    @exists (err, created) -> if created then cb null else obj.create cb
  write: (key, value, cb) ->
    obj = this
    @emit 'write', key, value
    @adapter.write key, value, (err, res) ->
      obj.emit 'written', key, value
      cb err, res
  read: (key, cb) ->
    @emit 'read', key
    @adapter.read key, cb
  remove: (key, cb) -> @adapter.remove key, cb
  readAll: (keys, cb) ->
    obj = this
    async.map keys, ((each, cb) -> obj.read each, cb), cb
  writeAll: (keyValues, cb) ->
    obj = this
    async.map keyValues, (({key, value}, cb) -> obj.write key, value, cb), cb
  removeAll: (keys, cb) ->
    obj = this
    async.map keys, ((each, cb) -> obj.remove each, cb), cb
  keys: (cb) -> @adapter.keys cb
  pipe: (toStore) -> @on 'write', (key, value) -> toStore.write key, value, ->

wrapAdapter = (requireFun) ->
  (args...) ->
    adapter = requireFun()
    new PluggableStore adapter: new adapter(args...)

PluggableStore.browser =
  localStorage: wrapAdapter -> require './localstorage'
PluggableStore.server =
  fileSystem: wrapAdapter -> require './filesystem'
PluggableStore.memory = wrapAdapter -> require './memory'

module.exports = PluggableStore