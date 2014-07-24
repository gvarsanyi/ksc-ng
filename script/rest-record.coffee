
app.factory 'ksc.RestRecord', [
  '$http', 'ksc.Record', 'ksc.RestUtils', 'ksc.Utils',
  ($http, Record, RestUtils, Utils) ->

    REST_PENDING = '_restPending'

    define_value = Utils.defineValue


    class RestRecord extends Record
      constructor: ->
        define_value @, REST_PENDING, 0
        super

      _restLoad: (callback) ->
        unless endpoint = @_options.endpoint
          throw new Error 'Missing endpoint'

        RestRecord.async @, $http.get(endpoint.url), callback


      @async: (record, promise, callback) ->
        define_value record, REST_PENDING, record[REST_PENDING] + 1

        RestUtils.wrapPromise promise, (err, raw_response) ->
          define_value record, REST_PENDING, record[REST_PENDING] - 1

          if not err and raw_response.data
            record._replace raw_response.data

          callback? err, raw_response
]
