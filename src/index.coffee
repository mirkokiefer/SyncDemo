window.jQuery = window.$ = require 'jquery-browserify'
window.Backbone = require 'backbone'
Backbone.setDomLibrary($)
window._ = require 'underscore'
{render} = require 'mustache'
template = (templateString) -> (data) -> render templateString, data
{Repository} = require 'synclib'
{List, ListItem} = require 'backbone-listview'

main = ->
  repo = new Repository
  branch = repo.branch()

  data1 = 
    "a/b": "test1"
    "a/c": "test2"
    "d": "test3"
  data2 =
    "a/b": "test1modified"
    "e/f/g": "test4"
  branch.commit data1
  branch.commit data2
  Entry = Backbone.Model.extend {}
  EntryList = Backbone.Collection.extend model: Entry

  paths = new EntryList
  entry1 = new Entry path: 'test1', value: 'value1'
  entry2 = new Entry path: 'test2', value: 'value2'
  console.log branch.allPaths()
  paths.reset branch.allPaths()

  PathView = ListItem.extend
    tagName: 'li'
    template: template '{{path}}'

  pathListView = new List itemView: PathView, collection: paths
  pathListView.on 'selected', (entry) ->
    $('#note').text entry.get 'value'

  $('#master').html pathListView.render().el

$(main)