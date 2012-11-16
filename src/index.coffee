window.jQuery = window.$ = require 'jquery-browserify'
window.Backbone = require 'backbone'
Backbone.setDomLibrary($)
{omit, difference} = window._ = require 'underscore'
{Repository} = require 'synclib'
{PathView, EntryView, EntryListView} = require './views'

renderView = (view, selector) -> $(selector).html view.render().el

repo = new Repository
branch = repo.branch()
remotes = {}
clientName = -> $('#client').val()

Entry = Backbone.Model.extend idAttribute: 'path'
EntryList = Backbone.Collection.extend model: Entry

entries = new EntryList
changedEntries = new Backbone.Collection
changed = (model) -> changedEntries.add model
trackChanges = (model) -> model.on 'change', -> changed model

resetEntries = ->
  data = branch.allPaths()
  models = data.map ({path, value}) ->
    entry = new Entry JSON.parse value
    entry.set entry.idAttribute, path
    trackChanges entry
    entry
  entries.reset models
  entries.add changedEntries.models

deltaData = ->
  delta = branch.deltaHashs from: remotes.me
  for remote, remoteHead of remotes
    knownPatch = repo.deltaHashs from: remotes.me, to: remoteHead
    delta.trees = difference delta.trees, knownPatch.trees
    delta.data = difference delta.data, knownPatch.data
  repo.deltaData delta

commitChanges = ->
  data = {}
  for model in changedEntries.models
    data[model.id] = JSON.stringify omit(model.toJSON(), model.idAttribute)
  branch.commit data
  changedEntries.reset()
  delta = deltaData()
  console.log 'send delta', delta
  $.post '/delta', {trees: delta.trees}, ->
    remotes.me = branch.head
    $.ajax(type: 'PUT', url:'/head/'+clientName(), data:hash:branch.head)

fetchChanges = ->
  $.get '/head', (res) ->
    res.heads.map ({name, head}) ->
      remotes[name] = head
      fromString = if remotes.me then 'from='+remotes.me + '&' else ''
      $.get '/delta?' + fromString + 'to=' + head, (res) ->
        repo.treeStore.writeAll res.trees
        branch.merge ref: head
        resetEntries()
        console.log 'delta from', name, res

main = ->
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
  $('#btn-commit').click -> commitChanges()
  $('#btn-fetch').click -> fetchChanges()

  renderView entryListView, '#entries'

$(main)