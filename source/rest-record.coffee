
main.factory 'kareo.RestRecord', [
  '$http', 'kareo.EditableRecord', 'kareo.restUtils',
  ($http, EditableRecord, restUtils) ->

    async = (record, promise, callback) ->
      restUtils.wrapPromise promise, (err, raw_response) ->
        if not err and raw_response.data
          record._replace raw_response.data
        callback? err, raw_response


    class RestRecord extends EditableRecord
      _restLoad: (callback) ->
        async @, $http.get(@_restOptions.url), callback

      _restSave: (callback) ->
        async @, $http.put(@_restOptions.url, @_entity()), callback
]
