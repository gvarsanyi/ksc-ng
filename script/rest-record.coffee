
app.factory 'ksc.RestRecord', [
  '$http', 'ksc.Record', 'ksc.RestUtils', 'ksc.TypeError', 'ksc.Utils',
  'ksc.ValueError',
  ($http, Record, RestUtils, TypeError, Utils,
   ValueError) ->

    REST_PENDING = '_restPending'

    define_value = Utils.defineValue

    ###
    Record with REST load binding ($http GET wrapper)

    @example
        record = new EditableRestRecord null, {endpoint: {url: '/test'}}
        record._restLoad (err, raw_response) ->
          console.log 'Done with', err, 'error'
          console.log record # will show record with loaded values

    Option used:
    - .options.endpoint.url

    @author Greg Varsanyi
    ###
    class RestRecord extends Record
      # @property [number] number of pending REST requests (of any kind) - may
      # be used a load indicator
      _restPending: 0

      constructor: ->
        define_value @, REST_PENDING, 0
        super

      ###
      Trigger loading data from the record-style endpoint specified in
      _options.endpoint.url

      Bumps up ._restPending counter by 1 when starting to load (and will
      decrease by 1 when done)

      @param [function] callback (optional) will call back with signiture:
        (err, raw_response) ->
      @option raw_response [Error] error (optional) $http error
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [ValueError] Missing endpoint url value
      @throw [TypeError] Endpoint url is not a string

      @return [HttpPromise] promise object created by $http
      ###
      _restLoad: (callback) ->
        url = RestRecord.getUrl @

        RestRecord.async @, $http.get(url), callback


      ###
      Helper that wraps request, increases/decreases pending load counter and
      updates data on incoming

      @param [Record] record reference to data container
      @param [HttpPromise] promise $http promise that should be wrapped
      @param [function] callback (optinal) callback function
        (see: {RestRecord#_restLoad})

      @return [HttpPromise] the promise that was wrapped
      ###
      @async: (record, promise, callback) ->
        define_value record, REST_PENDING, record[REST_PENDING] + 1

        RestUtils.wrapPromise promise, (err, raw_response) ->
          define_value record, REST_PENDING, record[REST_PENDING] - 1

          if not err and raw_response.data
            record._replace raw_response.data

          callback? err, raw_response

      ###
      Get the url from _options.endpoint.url or throw errors as needed

      @param [Record] record reference to data container

      @throw [ValueError] Missing endpoint url value
      @throw [TypeError] Endpoint url is not a string

      @return [string] url
      ###
      @getUrl: (record) ->
        unless (endpoint = record._options.endpoint) and url = endpoint.url
          throw new ValueError 'Missing options.endpoint.url'

        unless typeof url is 'string'
          throw new TypeError 'Missing options.endpoint.url'

        url
]
