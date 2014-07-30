
app.factory 'ksc.RestRecord', [
  '$http', 'ksc.Errors', 'ksc.Record', 'ksc.RestUtils', 'ksc.Utils',
  ($http, Errors, Record, RestUtils, Utils) ->

    OPTIONS      = '_options'
    REST_CACHE   = '_restCache'
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
    - ._options.cache
    - ._options.endpoint.url

    @author Greg Varsanyi
    ###
    class RestRecord extends Record
      # @property [object] load promise used if ._options.cache is set
      _restCache: null

      # @property [number] number of pending REST requests (of any kind) - may
      # be used a load indicator
      _restPending: 0

      constructor: ->
        define_value @, REST_PENDING, 0
        super

      ###
      Trigger loading data from the record-style endpoint specified in
      _options.cache
      _options.endpoint.url

      Bumps up ._restPending counter by 1 when starting to load (and will
      decrease by 1 when done)

      @param [boolean] force_load (optinal) request disregarding cache
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
      _restLoad: (force_load, callback) ->
        record = @

        get = ->
          url = RestRecord.getUrl record
          RestRecord.async record, $http.get(url), callback

        unless typeof force_load is 'boolean'
          callback = force_load
          force_load = null

        if not record[OPTIONS].cache or not record[REST_CACHE] or force_load
          define_value record, REST_CACHE, get callback
        else if callback
          RestUtils.wrapPromise record[REST_CACHE], callback

        record[REST_CACHE]


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
        unless (endpoint = record[OPTIONS].endpoint) and (url = endpoint.url)?
          throw new Errors.Value 'Missing _options.endpoint.url'

        unless typeof url is 'string'
          throw new Errors.Type '_options.endpoint.url', 'string'

        url
]
