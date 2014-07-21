
app.factory 'ksc.RestRecord', [
  '$http', 'ksc.Record', 'ksc.RestUtils',
  ($http, Record, RestUtils) ->

    class RestRecord extends Record
      _restLoad: (callback) ->
        unless endpoint = @_options.endpoint
          throw new Error 'Missing endpoint'

        RestRecord.async @, $http.get(endpoint.url), callback

      @async: (record, promise, callback) ->
        RestUtils.wrapPromise promise, (err, raw_response) ->
          if not err and raw_response.data
            record._replace raw_response.data
          callback? err, raw_response
]
