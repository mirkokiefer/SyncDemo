bb = require 'backbone'

ListItem = bb.View.extend
  initialize: () ->
    this.model.on 'change', this.render, this
  tagName: 'li'
  events:
    "click": "select"
  select: () -> this.trigger 'selected', this
  selected: (isSelected) ->
    if isSelected then this.isSelected = true else this.isSelected = false
    this.render()
  render: () ->
    data = this.model.toJSON()
    data.isSelected = this.isSelected
    @$el.html(@template(@model.toJSON()))
    this

module.exports = ListItem