
app.factory 'ksc.HttpError', ->

  class HttpError extends Error

    constructor: (http_result) ->
      {data, status, headers, config} = http_result
      super 'HTTP' + status + ': ' + config.method + ' ' + config.url
