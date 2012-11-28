window.jQuery = window.$ = require 'jquery-browserify'
window.Backbone = require 'backbone'
async = require 'async'
Backbone.setDomLibrary($)
{omit, difference, values, pluck} = window._ = require 'underscore'
{Repository} = require 'synclib'
{PathView, EntryView, EntryListView} = require './views'
{post, put, get} = require './utils'

Entry = Backbone.Model.extend idAttribute: 'path'
EntryList = Backbone.Collection.extend model: Entry

renderView = (view, selector) -> $(selector).html view.render().el

resetCollection = (collection, branch) ->
  branch.allPaths (err, data) ->
    models = data.map ({path, value}) ->
      entry = JSON.parse value
      entry.path = path
      entry
    collection.reset models

commitModels = (models, branch, cb) ->
  data = {}
  for model in models
    data[model.id] = JSON.stringify omit(model.toJSON(), model.idAttribute)
  branch.commit data, cb

class SyncClient
  constructor: ({@branch, @name}={}) ->
    @remotes = {}
  fetch: (cb) ->
    obj = this
    get '/head', (err, {heads}) ->
      from = JSON.stringify values(obj.remotes)
      to = JSON.stringify pluck(heads, 'head')
      get '/delta?from=' + from + '&to=' + to, (err, res) ->
        console.log 'delta received', res
        obj.branch.repo.applyDelta res, ->
          mergeEach = ({name, head}, cb) ->
            obj.branch.merge ref: head, ->
              obj.remotes[name] = head
              cb null
          async.forEach heads, mergeEach, cb
  push: (cb) ->
    obj = this
    @branch.delta from: values(@remotes), (err, delta) ->
      post '/delta', delta, ->
        obj.remotes[obj.name] = obj.branch.head
        put '/head/'+obj.name, {hash:obj.branch.head}, -> cb null

init = (name) ->
  repo = new Repository
  branch = repo.branch()
  syncClient = new SyncClient branch: branch, name: name

  entries = new EntryList
  changedEntries = new Backbone.Collection
  changed = (model) -> changedEntries.add model
  trackChanges = (model) -> model.on 'change', -> changed model

  entries.on 'reset', ->
    (trackChanges each for each in entries.models)
  entries.on 'add', (model) ->
    trackChanges model
    changed model

  entryListView = new EntryListView collection: entries
  entryListView.on 'selected', (entry) ->
    entryView = new EntryView model: entry
    entryView.on 'save', (newEntry) ->
      entry.set newEntry
    renderView entryView, '#detail'

  $('#btn-add').click ->
    entryView = new EntryView()
    entryView.on 'save', (newEntry) ->
      entries.add newEntry
    renderView entryView, '#detail'
  $('#btn-commit').click ->
    commitModels changedEntries.models, branch, ->
      changedEntries.reset()
  $('#btn-push').click -> syncClient.push ->
  $('#btn-fetch').click ->
    syncClient.fetch -> resetCollection entries, branch

  renderView entryListView, '#entries'

queryName = (cb) ->
  $('#setup-modal').modal backdrop: 'static', keyboard: false
  $('#setup-modal .submit').click ->
    $('#setup-modal').modal 'hide'
    cb null, $('#setup-client').val()

$ -> queryName (err, name) ->
  $('#client-name').text name
  init name
