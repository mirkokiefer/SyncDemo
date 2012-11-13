{render} = require 'mustache'
{List, ListItem} = require 'backbone-listview'
template = (templateString) -> (data) -> render templateString, data

BaseView = Backbone.View.extend
  templateData: -> @model.toJSON()
  render: ->
    @$el.html @template @templateData()
    this

PathView = ListItem.extend
  tagName: 'li'
  template: template '{{path}}'

EntryView = BaseView.extend
  template: template '''
  <form>
    <fieldset>
      <legend>Note</legend>
      <input type="text" id="form-path" {{#uneditable}}disabled{{/uneditable}} placeholder="Path" value="{{path}}">
      <textarea id="form-note" class="input-block-level" rows=5 placeholder="Enter your note…">{{value}}</textarea>
      <span class="help-block"></span>
      <a class="btn btn-save" href="#">Save</a>
      <a class="btn btn-delete" href="#">Delete</a>
    </fieldset>
  </form>
  '''
  events:
    'click .btn-save': 'save'
    'click .btn-delete': 'delete'
  save: ->
    changedModel = path: @$('#form-path').val(), value: @$('#form-note').val()
    @trigger 'save', changedModel
  delete: ->
  templateData: ->
    if @model
      data = @model.toJSON()
      data.uneditable = true
      data
    else {}

EntryListView = List.extend itemView: PathView

module.exports =
  PathView: PathView
  EntryView: EntryView
  EntryListView: EntryListView