
app.factory 'ksc.BatchLoader', [
  '$http', '$q', 'ksc.batchLoaderRegistry', 'ksc.error', 'ksc.utils',
  ($http, $q, batchLoaderRegistry, error, utils) ->

    argument_type_error = error.ArgumentType
    is_object           = utils.isObject

    ###
    Batch loader class that can take GET requests for predefined URLs and
    create individual promises, send the joint request and resolve all
    individual promises

    The joint rquest is sent with method PUT

    Also supports states (open: true|false)

    Suggested use: bootstrap implementations with many HTTP GET requests

    @author Greg Varsanyi
    ###
    class BatchLoader

      # @property [string] url of rest-loader endpoint
      endpoint: null

      # @property [object] key-value map (of endpoint keys and urls)
      map: null

      # @property [boolean] whether batch loader accepts requests
      #   setting to false triggers flush()
      open: true

      # @property [Array] list of registered requests (waiting for `.flush()`)
      requests: null

      ###

      @param [string] endpoint URL of
      @param [object] map key-value map of endpoint keys and URL matchers

      @throw [ArgumentTypeError] missing or mismatching endpoint or map
      @throw [TypeError] invalid map entry
      ###
      constructor: (@endpoint, @map) ->
        loader = @

        unless typeof endpoint is 'string'
          argument_type_error {endpoint, required: 'string'}

        unless is_object map
          argument_type_error {map, required: 'object'}
        for key, url in map when typeof url isnt 'string' or not key
          error.Type {key, url, required: 'url string'}

        open = true
        setter = (value) ->
          if open and not value
            loader.flush()
          loader.open = open = !!value
        utils.defineGetSet loader, 'open', (-> loader.open), setter, true

        utils.defineValue loader, 'requests', [], false, true

        batchLoaderRegistry.register loader

      ###
      Add to the request list if the request is acceptable

      @param [string] url individual requests URL
      @param [object] query_parameters query arguments on a key-value map

      @throw [ArgumentTypeError] if url is not a string or invalid query params

      @return [false|Promise] individual mock promise for http response
      ###
      get: (url, query_parameters) ->
        loader   = @
        requests = loader.requests

        unless typeof url is 'string'
          argument_type_error {url, required: 'string'}

        if query_parameters and not is_object query_parameters
          argument_type_error {query_parameters, required: 'object'}

        unless loader.open
          return false

        for key, value of loader.map when url is value
          matched_key = key
          break

        unless matched_key
          return false

        promise = $q.defer()

        requests.push {resource: matched_key, promise}

        if query_parameters
          requests[requests.length - 1].query = query_parameters

        promise

      ###
      Flush requests (if any)

      @return [false|Promise] joint request promise (or false on no request)
      ###
      flush: ->
        loader   = @
        requests = loader.requests

        unless requests.length
          return false

        promises = []
        for request in requests
          promises.push request.promise
          delete request.promise

        batch_promise = $http.put loader.endpoint, requests

        batch_promise.success (data, status, headers, config) ->
          for promise, i in promises
            unless (response = data[i])?
              promise.reject data, status, headers, config
            else if 200 <= response.status < 400
              promise.resolve response.data, response.status, headers, config
            else
              promise.reject response.data, response.status, headers, config

        batch_promise.error (data, status, headers, config) ->
          for promise in promises
            promise.reject data, status, headers, config
]
