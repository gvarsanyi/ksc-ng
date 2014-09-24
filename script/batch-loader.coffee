
app.factory 'ksc.BatchLoader', [
  '$http', '$q', 'ksc.batchLoaderRegistry', 'ksc.error', 'ksc.util',
  ($http, $q, batchLoaderRegistry, error, util) ->

    argument_type_error = error.ArgumentType
    is_object           = util.isObject

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

        unless endpoint and typeof endpoint is 'string'
          argument_type_error {endpoint, required: 'string'}

        unless is_object map
          argument_type_error {map, required: 'object'}
        for key, url of map when typeof url isnt 'string' or not key
          error.Type {key, url, required: 'url string'}

        open = true
        setter = (value) ->
          if open and not value
            loader.flush()
          open = !!value
        util.defineGetSet loader, 'open', (-> open), setter, true

        util.defineValue loader, 'requests', [], false, true

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

        unless url and typeof url is 'string'
          argument_type_error {url, required: 'string'}

        if query_parameters? and not is_object query_parameters
          argument_type_error {query_parameters, required: 'object'}

        unless loader.open
          return false

        for key, value of loader.map when url is value
          matched_key = key
          break

        unless matched_key
          return false

        deferred = $q.defer()

        requests.push {resource: matched_key, deferred}

        if query_parameters
          requests[requests.length - 1].query = query_parameters

        deferred.promise

      ###
      Flush requests (if any)

      @return [false|Promise] joint request promise (or false on no request)
      ###
      flush: ->
        loader   = @
        requests = loader.requests

        unless requests.length
          return false

        defers = []
        for request in requests
          defers.push request.deferred
          delete request.deferred

        batch_promise = $http.put loader.endpoint, requests

        batch_promise.success (data, status, headers, config) ->
          for deferred, i in defers
            unless (res = data[i])?
              deferred.reject {data, status, headers, config}
              continue

            raw = {data: res.body, status: res.status, headers, config}
            if 200 <= res.status < 400
              deferred.resolve raw
            else
              deferred.reject raw
          return

        batch_promise.error (data, status, headers, config) ->
          for deferred in defers
            deferred.reject {data, status, headers, config}
          return
]
