window.jQuery = window.$ = require 'jquery-browserify'
window.Backbone = require 'backbone'
Backbone.setDomLibrary($)
{omit} = window._ = require 'underscore'
{Repository} = require 'synclib'
{PathView, EntryView, EntryListView} = require './views'

renderView = (view, selector) -> $(selector).html view.render().el

repo = new Repository
branch = repo.branch()

Entry = Backbone.Model.extend idAttribute: 'path'
EntryList = Backbone.Collection.extend model: Entry

paths = new EntryList

resetEntries = ->
  data = branch.allPaths()
  models = data.map ({path, value}) ->
    entry = new Entry JSON.parse value
    entry.set entry.idAttribute, path
    entry.on 'change', -> commitModels [entry]
    entry
  paths.reset models

commitModels = (models) ->
  data = {}
  for model in models
    data[model.id] = JSON.stringify omit(model.toJSON(), model.idAttribute)
  branch.commit data
  console.log branch.head, data

addTestData = (branch) ->
  data = 
    "a/b": JSON.stringify(value: "test1")
    "b": JSON.stringify(value: "test2")
  branch.commit data

main = ->
  addTestData branch
  resetEntries()

  paths.on 'add', (model) ->
    model.on 'change', -> commitModels [model]
    commitModels [model]

  entryListView = new EntryListView collection: paths
  entryListView.on 'selected', (entry) ->
    entryView = new EntryView model: entry
    entryView.on 'save', (newEntry) ->
      entry.set newEntry.toJSON()
    renderView entryView, '#detail'

  $('#btn-add').click ->
    entryView = new EntryView()
    entryView.on 'save', (newEntry) ->
      paths.add newEntry
    renderView entryView, '#detail'

  renderView entryListView, '#paths'

$(main)