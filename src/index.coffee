window.jQuery = window.$ = require 'jquery-browserify'
window.Backbone = require 'backbone'
async = require 'async'
Backbone.setDomLibrary($)
{omit, difference, values, pluck} = window._ = require 'underscore'
{Repository} = require 'synclib'
{PathView, EntryView, EntryListView} = require './views'

Entry = Backbone.Model.extend idAttribute: 'path'
EntryList = Backbone.Collection.extend model: Entry

renderView = (view, selector) -> $(selector).html view.render().el

resetCollection = (collection, branch) ->
  data = branch.allPaths()
  models = data.map ({path, value}) ->
    entry = new Entry JSON.parse value
    entry.set entry.idAttribute, path
    entry
  collection.reset models

commitModels = (models, branch) ->
  data = {}
  for model in models
    data[model.id] = JSON.stringify omit(model.toJSON(), model.idAttribute)
  branch.commit data

class SyncClient
  constructor: ({@branch, @name}={}) ->
    @remotes = {}
  fetch: (cb) ->
    obj = this
    $.get '/head', ({heads}) ->
      from = JSON.stringify values(obj.remotes)
      to = JSON.stringify pluck(heads, 'head')
      $.get '/delta?from=' + from + '&to=' + to, (res) ->
        console.log 'delta received', res
        obj.branch.repo.treeStore.writeAll res.trees
        for {name, head} in heads
          obj.branch.merge ref: head
          obj.remotes[name] = head
        cb null
  push: ->
    obj = this
    delta = @branch.repo.deltaData @branch.deltaHashs from: values(@remotes)
    console.log 'send delta', delta
    $.ajax
      type:'POST'
      url:'/delta'
      data: JSON.stringify {trees: delta.trees}
      contentType:"application/json; charset=utf-8"
      dataType:"json"
      success: ->
        obj.remotes[obj.name] = obj.branch.head
        $.ajax(type: 'PUT', url:'/head/'+obj.name, data: {hash:obj.branch.head})

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
    commitModels changedEntries.models, branch
    changedEntries.reset()
  $('#btn-push').click -> syncClient.push()
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
