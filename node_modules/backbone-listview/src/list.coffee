
bb = require 'backbone'
ListItem = require './list-item'

List = bb.View.extend
  initialize: () ->
    if @options.itemView then @itemView = @options.itemView
    col = this.collection
    col.on 'add', this.addModel, this
    col.on 'remove', this.removeModel, this
    col.on 'reset', this.resetCollection, this
    this.resetCollection()
  itemView: ListItem
  tagName: 'ul'
  createItemView: (model) ->
    view = new this.itemView(model: model).render()
    view.on 'selected', this.select, this
    view
  select: (view) ->
    if this.selectedView then this.selectedView.selected false
    view.selected true
    this.selectedView = view
    this.trigger 'selected', view.model
  addModel: (model) ->
    view = this.createItemView model
    this.viewCollection.push(view)
    this.render()
  removeModel: (model) ->
    view = _(this.viewCollection).find (each) -> each.model == model
    view.remove()
    delete this.viewCollection[model.cid]
  resetCollection: () ->
    this.viewCollection = this.collection.map this.createItemView, this
    this.render()
  render: () ->
    $(this.el).empty()
    $el = this.$el
    this.viewCollection.forEach (view) ->
      view.delegateEvents()
      $el.append view.el
    this

module.exports = List