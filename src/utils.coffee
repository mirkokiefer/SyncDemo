
post = (url, data, cb) ->
  $.ajax
    type: 'POST',
    url:url,
    data: JSON.stringify(data),
    contentType: "application/json; charset=utf-8"
    dataType:"json"
    success: (res) -> cb null, res
put = (url, data, cb) ->
  $.ajax
    type: 'PUT',
    url: url,
    data: JSON.stringify(data),
    contentType: "application/json; charset=utf-8",
    dataType:"json",
    success: (res) -> cb null, res
get = (url, cb) -> $.get url, (res) -> cb null, res

module.exports =
  post: post
  put: put
  get: get