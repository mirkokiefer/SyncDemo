express    = require 'express'
path       = require 'path'
browserify = require 'browserify'
syncnode = require 'syncnode'

app = module.exports = express()

app.configure ->
  app.set 'views', path.join(__dirname, 'views')
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use app.router
  app.use browserify __dirname + '/src/index.coffee', debug: true, watch: true
  app.use express.static path.join(__dirname, 'public')
  app.use syncnode()

app.configure 'development', ->
  app.use express.errorHandler dumpExceptions: true, showStack: true

app.configure 'production', -> app.use express.errorHandler()

server = app.listen 3000, 'localhost', ->
  console.log "server listening at http://localhost:#{server.address().port}"
