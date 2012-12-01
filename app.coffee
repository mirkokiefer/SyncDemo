express = require 'express'
path = require 'path'
fs = require 'fs'
async = require 'async'
browserify = require 'browserify'
syncnode = require 'syncnode'
{memory, server} = require 'pluggable-store'
cache = require 'pluggable-cache'
contentAddressable = require 'content-addressable'

storeDir = process.env.HOME+'/syncnode'

cachingStore = (name) ->
  persistentStore = server.fileSystem storeDir+'/'+name
  cache cache: memory(), persistence: persistentStore
cachingCAStore = (name) ->
  new contentAddressable.Interface store: cachingStore name

[commitStore, treeStore] = ['commits', 'trees'].map cachingCAStore
headStore = cachingStore 'heads'
blobStoreBackend = server.fileSystem storeDir+'/'+'blobs'
blobStore = new contentAddressable.Interface store: blobStoreBackend
repository = new syncnode.synclib.Repository commitStore: commitStore, treeStore: treeStore
initStores = (cb) ->
  fs.mkdir storeDir, ->
    async.map [commitStore.store, treeStore.store, headStore, blobStore.store], ((each, cb) -> each.ensureStore cb), cb

app = module.exports = express()

app.configure ->
  app.set 'views', path.join(__dirname, 'views')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use browserify __dirname + '/src/index.coffee', debug: true, watch: true
  app.use express.static path.join(__dirname, 'public')
  app.use syncnode repository: repository, headStore: headStore, blobStore: blobStore

app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', -> app.use express.errorHandler()

initStores ->
  server = app.listen 3000, 'localhost', ->
    console.log "server listening at http://localhost:#{server.address().port}"
