
assert = require 'assert'
req = require 'superagent'
{Repository, TreeStore, backend} = require 'synclib'
contentAddressable = require 'content-addressable'
createApp = require '../lib/index'
{difference, values} = require 'underscore'
async = require 'async'

testPort = 3001
url = (path) -> 'http://localhost:' + testPort + path

app = createApp()

class Client
  constructor: ->
    @blobStore = contentAddressable.memory()
    @repo = new Repository()
    @branch = @repo.branch()
    @remotes = {}

client1 = new Client()
client2 = new Client()

dataA = [
  {'a': "hashA 0.0", 'b/c': "hashA 0.1", 'b/d': "hashA 0.2"}
  {'a': "hashA 1.0", 'b/c': "hashA 1.1", 'b/e': "hashA 1.2", 'b/f/g': "hashA 1.3"}
  {'b/e': "hashA 2.0"}
]
dataB = [
  {'b/h': "hashB 0.0"}
  {'c/a': "hashB 1.0"}
  {'a': "hashB 2.0", 'u': "hashB 2.1"}
  {'b/c': "hashB 3.0", 'b/e': "hashB 3.1", 'b/f/a': "hashB 3.2"}
]

before (done) -> app.listen testPort, 'localhost', done

describe 'http-interface', ->
  describe 'blob storage', ->
    it 'should POST some data and return the hash to GET it', (done) ->
      data = data: "some data"
      req.post(url '/blob').send(data).end (res) ->
        hash = res.body.hash
        req.get(url '/blob/'+hash).end (res) ->
          assert.equal res.body.data, data.data
          done()
  describe 'client1', ->
    it 'should do some local commits and POST the diff to the server', (done) ->
      async.forEach dataA, ((each, cb) -> client1.branch.commit each, cb), ->
        client1.branch.delta {}, (err, delta) ->
          req.post(url '/delta').send(delta).end (res) ->
            assert.ok res.body.ok
            done()
    it 'should set its head on the server', (done) ->
      req.put(url '/head/client1').send(hash: client1.branch.head).end (res) ->
        req.get(url '/head/client1').end (res) ->
          assert.equal res.body.hash, client1.branch.head
          client1.remotes.client1 = res.body.hash
          done()
  describe 'client2', ->
    it 'should do some commits and push the diff', (done) ->
      async.forEach dataB, ((each, cb) -> client2.branch.commit each, cb), ->
        client2.branch.delta {}, (err, delta) ->
          req.post(url '/delta').send(delta).end ->
            client2.remotes.client2 = client2.branch.head
            done()
    it 'should ask for client1\'s head', (done) ->
      req.get(url '/head/client1').end (res) ->
        client2.remotes.client1 = res.body.hash
        done()
    it 'should ask for the delta to client1 head', (done) ->
      [from, to] = (JSON.stringify each for each in [[client2.remotes.client2], [client2.remotes.client1]])
      req.get(url '/delta?from='+from+'&to='+to).end (res) ->
        client2.repo.applyDelta res.body, done
    it 'should do a local merge of client1s diff', (done) ->
      oldHead = client2.branch.head
      client2.branch.merge ref: client2.remotes.client1, (err, head) ->
        client2.repo._commitStore.read head, (err, headObj) ->
          assert.equal difference(headObj.ancestors, [client2.remotes.client1, oldHead]).length, 0
          done()
    it 'should push its new diff to the server', (done) ->
      client2.branch.delta from: values(client2.remotes), (err, delta) ->
        req.post(url '/delta').send(delta).end ->
          client2.remotes.client2 = client2.branch.head
          done()
    it 'should update its head on the server', (done) ->
      req.put(url '/head/client2').send(hash: client2.branch.head).end (res) ->
        done()
  describe 'client1 - step 2', ->
    it 'should ask for client2 head and fetch the delta', (done) ->
      req.get(url '/head/client2').end (res) ->
        client1.remotes.client2 = res.body.hash
        [from, to] = (JSON.stringify each for each in [[client1.remotes.client1], [client1.remotes.client2]])
        req.get(url '/delta?from='+from+'&to='+to).end (res) ->
          client1.repo.applyDelta res.body, done
    it 'does a local fast-forward merge', (done) ->
      client1.branch.merge ref: client1.remotes.client2, (err, head) ->
        assert.equal head, client1.remotes.client2
        done()
    it 'fetches all client heads', (done) ->
      req.get(url '/head').end (res) ->
        assert.equal res.body.heads[0].name, 'client1'
        done()

      
