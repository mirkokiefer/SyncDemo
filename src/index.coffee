window.Backbone = require 'backbone'
window._ = require 'underscore'
window.$ = require 'jquery-browserify'
{Repository} = require 'synclib'

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
console.log branch.head