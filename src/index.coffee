window.jQuery = window.$ = require 'jquery-browserify'
window.Backbone = require 'backbone'
Backbone.setDomLibrary($)
{omit} = window._ = require 'underscore'
{Repository} = require 'synclib'
{PathView, EntryView, EntryListView} = require './views'

renderView = (view, selector) -> $(selector).html view.render().el

repo = new Repository
branch = repo.branch()
remotes =
  me: null

Entry = Backbone.Model.extend idAttribute: 'path'
EntryList = Backbone.Collection.extend model: Entry

entries = new EntryList

resetEntries = ->
  data = branch.allPaths()
  models = data.map ({path, value}) ->
    entry = new Entry JSON.parse value
    entry.set entry.idAttribute, path
    entry.on 'change', -> commitModels [entry]
    entry
  entries.reset models

commitModels = (models) ->
  data = {}
  for model in models
    data[model.id] = JSON.stringify omit(model.toJSON(), model.idAttribute)
  branch.commit data
  console.log branch.head, data
  delta = repo.deltaData branch.deltaHashs from: remotes.me
  $.post '/delta', {trees: delta.trees}, ->
    remotes.me = branch.head
    $.ajax(type: 'PUT', url:'/head/'+$('#client').val(), data:hash:branch.head)
    $.get '/head', (res) ->
      res.heads.map ({name, head}) ->
        remotes[name] = head
        $.get '/delta?from='+remotes.me + '&to=' + head, (res) ->
          repo.treeStore.writeAll res.trees
          branch.merge ref: head
          resetEntries()
          console.log name, res
  console.log delta

addTestData = (branch) ->
  data = 
    "a/b": JSON.stringify(value: "test1")
    "b": JSON.stringify(value: "test2")
  branch.commit data

main = ->
  addTestData branch
  resetEntries()

  entries.on 'add', (model) ->
    model.on 'change', -> commitModels [model]
    commitModels [model]

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

  renderView entryListView, '#entries'

$(main)