#content-addressable store
A content-addressable store interface that can be used with any [pluggable-store](https://github.com/mirkok/pluggable-store).

##Usage example

```js
ContentAddressable = require('../lib/index')

memoryStore = require('pluggable-store').server().memory()
contentAddressable = new ContentAddressable({store: memoryStore})

// depending on your pluggable store you can read/write synchronous:
hash = contentAddressable.write('value1')
value = contentAddressable.read(hash)

// async operations always work:
contentAddressable.write('value1', function(err, hash) {
  contentAddressable.read(hash, function(err, res) {
    ...
  })
})  
```
