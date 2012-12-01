
{memory} = require '../lib/index'
assert = require 'assert'

contentAddressable = memory()

describe 'ContentAddressable', () ->
  describe 'read/write', () ->
    it 'should write and read an object async', (done) ->
      contentAddressable.write 'value1', (err, hash) ->
        contentAddressable.read hash, (err, res) ->
          assert.equal res, 'value1'
          done()
    it 'should write and read multiple objects async', ->
      data = ['value1', 'value2']
      hashs = contentAddressable.writeAll data, (err, hashs) ->
        contentAddressable.readAll hashs, (err, readData) ->
          for each, i in readData
            assert.equal each, data[i]