window.Backbone = require 'backbone'
window._ = require 'underscore'
window.$ = require 'jquery-browserify'
Marionette = require 'Backbone.Marionette/lib/backbone.marionette'
{Store, backend} = require 'NodeStore'
backend = backend.browser()
LocalBackend = new backend.LocalStorage()
store = new Store LocalBackend
data1 = 
  "a/b": "test1"
  "a/c": "test2"
  "d": "test3"
data2 =
  "a/b": "test1modified"
  "e/f/g": "test4"
branch = store.branch()
branch.commit data1, (err, head1) ->
  branch.commit data2, ->
    oldBranch = store.branch head1
    oldBranch.read path: 'a/b', (err, res) -> console.log "old", res    
    branch.read path: 'a/b', (err, res) -> console.log res
console.log "test"