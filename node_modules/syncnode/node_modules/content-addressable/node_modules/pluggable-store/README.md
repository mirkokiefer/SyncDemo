#PluggableStore
A unified interface to key-value stores.


It comes bundled with these adapters:
* in-memory
* HTML5 local storage (only browser)
* file system (only node.js)

##Usage example
You can always read/write with callbacks - some adapters work synchronous as well:

``` js
pluggableStore = require('pluggable-store');
var store = pluggableStore.server().memory();

store.write('key1', 'value1');
res = store.read('key1');

store.write('key1', function() {
  store.read('key1', function(err, res) {
    ...
  })
})
```

