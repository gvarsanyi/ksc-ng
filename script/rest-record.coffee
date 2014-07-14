
app.factory 'ksc.RestRecord', [
  '$http', 'ksc.EditableRecord', 'ksc.RestUtils',
  ($http, EditableRecord, RestUtils) ->

    async = (record, promise, callback) ->
      RestUtils.wrapPromise promise, (err, raw_response) ->
        if not err and raw_response.data
          record._replace raw_response.data
        callback? err, raw_response


    class RestRecord extends EditableRecord
      _restLoad: (callback) ->
        async @, $http.get(@_restOptions.url), callback

      _restSave: (callback) ->
        async @, $http.put(@_restOptions.url, @_entity()), callback
]
