
angular.module('ksc').factory 'ksc.EditableRestRecord', [
  '$http', 'ksc.EditableRecord', 'ksc.Mixin', 'ksc.RestRecord',
  ($http, EditableRecord, Mixin, RestRecord) ->

    ###
    Stateful record with REST bindings (load and save)

    @example
        record = new EditableRestRecord {a: 1, b: 1}, {endpoint: {url: '/test'}}
        record._restSave (err, raw_response) ->
          console.log 'Done with', err, 'error'

    Option used:
    - .options.endpoint.url

    @author Greg Varsanyi
    ###
    class EditableRestRecord extends EditableRecord

      # @extend RestRecord
      Mixin.extend EditableRestRecord, RestRecord

      ###
      Trigger saving data to the record-style endpoint specified in
      _options.endpoint.url

      Uses PUT method

      Bumps up ._restPending counter by 1 when starting to load (and will
      decrease by 1 when done)

      @param [function] callback (optional) will call back with signiture:
        (err, raw_response) ->
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [ValueError] Missing endpoint url value
      @throw [TypeError] Endpoint url is not a string

      @return [HttpPromise] promise object created by $http
      ###
      _restSave: (callback) ->
        url = EditableRestRecord.getUrl @

        EditableRestRecord.async @, $http.put(url, @_entity()), callback
]
