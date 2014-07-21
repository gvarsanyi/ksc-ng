
app.factory 'ksc.EditableRestRecord', [
  '$http', 'ksc.EditableRecord', 'ksc.RestRecord',
  ($http, EditableRecord, RestRecord) ->

    class EditableRestRecord extends EditableRecord
      _restLoad: RestRecord::_restLoad

      _restSave: (callback) ->
        unless endpoint = @_options.endpoint
          throw new Error 'Missing endpoint'

        RestRecord.async @, $http.put(endpoint.url, @_entity()), callback
]
