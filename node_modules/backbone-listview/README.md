#backbone listview
A generic list view.

``` coffee
{ListItem, List} = require 'backbone-listview'

TestListItem = ListItem.extend

TestList = List.extend
itemView: TestListItem
```
