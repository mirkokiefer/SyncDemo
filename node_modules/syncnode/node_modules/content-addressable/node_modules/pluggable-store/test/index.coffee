
{server, memory} = require '../lib/index'
assert = require 'assert'
{contains} = require 'underscore'

assertEvent = (emitter, [event, expectedArgs], cb) ->
  emitter.once event, (args...) ->
    for each, i in expectedArgs
      assert.equal args[i], each
    cb()

assertEventsSerial = (emitter, events, cb) ->
  if events.length == 0 then cb()
  else
    [first, rest...] = events
    assertEvent emitter, first, -> assertEventsSerial emitter, rest, cb

store1 = null
fileStore = null
beforeEach -> store1 = memory()
before -> fileStore = server.fileSystem(process.env.HOME+'/test-store')
after (done) -> fileStore.adapter.delete done
testData = [{key: 'mult1', value: 'multval1'}, {key: 'mult2', value: 'multval2'}]
describe 'PluggableStore using Memory adapter', () ->
  describe 'read/write', () ->
    it 'should write and read an object', (done) ->
      store1.write 'key2', 'value2', () ->
        store1.read 'key2', (err, res) ->
          assert.equal res, 'value2'
          done()
    it 'should write and read multiple objects', (done) ->
      store1.writeAll testData, ->
        store1.read 'mult1', (err, res) ->
          assert.equal res, 'multval1'
          done()
    it 'should delete values', ->
      store1.write 'key1', 'value1', ->
        store1.remove 'key1', ->
          store1.read 'key1', (err, res) ->
            assert.equal res, undefined
  describe 'events', ->
    it 'should trigger write event on write', (done) ->
      assertEventsSerial store1, [
        ['write', ['key3', 'value3']]
        ['written', ['key3', 'value3']]
      ], done
      store1.write 'key3', 'value3', ->
    it 'should trigger read event on read', (done) ->
      assertEvent store1, ['read', ['key3']], done
      store1.read 'key3', ->
  describe 'keys', ->
    it 'should return all keys', ->
      store1.writeAll testData, ->
        store1.keys (err, keys) ->
          assert.ok contains(keys, key) for {key} in testData
          assert.equal keys.length, testData.length
  describe 'pipe', ->
    it 'should pipe the writes on one store to another', ->
      store2 = memory()
      store1.pipe store2
      store1.write 'key4', 'value4', ->
        store2.read 'key4', (err, res) ->
          assert.equal res, 'value4'
describe 'using FileSystem adapter', ->
  describe 'read/write', () ->
    it 'should write and read an object', (done) ->
      fileStore.write 'key2', 'value2', () ->
        fileStore.read 'key2', (err, res) ->
          assert.equal res, 'value2'
          done()
  describe 'keys', ->
    it 'should return all keys', (done) ->
      store1.writeAll testData, ->
        store1.keys (err, keys) ->
          assert.ok contains(keys, key) for {key} in testData
          assert.equal keys.length, testData.length
          done()