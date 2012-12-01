
class Memory
  constructor: () -> @data = {}
  createdStore: (cb) -> cb null, true
  createStore: (cb) -> cb null
  removeStore: (cb) -> @data = {}; cb null
  write: (path, data, cb) -> @data[path] = data; cb null
  read: (path, cb) -> cb null, @data[path]
  remove: (path, cb) -> delete @data[path]; cb null
  keys: (cb) -> cb null, Object.keys @data

module.exports = Memory