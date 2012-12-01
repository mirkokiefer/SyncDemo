
PluggableStore = require 'pluggable-store'
async = require 'async'

class Cache
  constructor: ({@cache, @persistence, @lazy}) ->
  exists: (cb) ->
    eachExists = (each, cb) -> each.exists cb
    async.every [@cache, @persistence], eachExists, cb
  create: (cb) ->
    createEach = (each, cb) ->
      each.exists (err, exists) ->
        if exists then cb null
        else each.create cb
    async.forEach [@cache, @persistence], createEach, cb
  destroy: (cb) ->
    async.forEach [@cache, @persistence], ((each, cb) -> each.destroy cb), cb
  write: (path, data, cb) ->
    if @lazy
      @cache.write path, data, cb
      @persistence.write path, data, ->
    else
      async.forEach [@cache, @persistence], ((each, cb) -> each.write path, data, cb), cb
  read: (path, cb) ->
    obj = this
    @cache.read path, (err, res) ->
      if res then cb null, res
      else
        obj.persistence.read path, (err, res) ->
          obj.cache.write path, res, ->
          cb null, res

  remove: (path, cb) ->
    if @lazy
      @cache.remove path, cb
      @persistence.remove path, ->
    else
      async.forEach [@cache, @persistence], ((each, cb) -> each.remove path, cb), cb
  keys: (cb) -> @persistence.keys cb
create = (opts) -> new PluggableStore adapter: (new Cache opts)
create.adapter = Cache
module.exports = create
