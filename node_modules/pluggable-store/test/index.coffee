
{server, memory} = require '../lib/index'
assert = require 'assert'
genericStoreTests = require 'pluggable-store-tests'

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

store = null
beforeEach -> store = memory()

describe 'memory adapter', genericStoreTests memory
describe 'filestore adapter', genericStoreTests -> server.fileSystem(process.env.HOME+'/test-store')
describe 'events', ->
  it 'should trigger write event on write', (done) ->
    assertEventsSerial store, [
      ['write', ['key3', 'value3']]
      ['written', ['key3', 'value3']]
    ], done
    store.write 'key3', 'value3', ->
  it 'should trigger read event on read', (done) ->
    assertEvent store, ['read', ['key3']], done
    store.read 'key3', ->
describe 'pipe', ->
  it 'should pipe the writes on one store to another', ->
    store2 = memory()
    store.pipe store2
    store.write 'key4', 'value4', ->
      store2.read 'key4', (err, res) ->
        assert.equal res, 'value4'
