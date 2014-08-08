
app.factory 'ksc.RestList', [
  '$http', 'ksc.List', 'ksc.error', 'ksc.restUtils', 'ksc.utils',
  ($http, List, error, restUtils, utils) ->

    REST_PENDING = 'restPending'

    define_value = utils.defineValue

    ###
    REST methods for ksc.List

    Load, save and delete records in bulks or individually

    @example
        list = new RestList
          endpoint:
            url: '/api/MyEndpoint'
          record:
            endpoint:
              url: '/api/MyEndpoint/<id>'

    Options that may be used by methods of ksc.RestList
    - .options.endpoint.bulkDelete (delete 2+ records in 1 request)
    - .options.endpoint.bulkSavel (save 2+ records in 1 request)
    - .options.endpoint.responseProperty (array of records in list response)
    - .options.endpoint.url (url for endpoint)
    - .options.record.endpoint.url (url for endpoint with record ID)

    Options that may be used by methods of ksc.List
    - .options.record.class (class reference for record objects)
    - .options.record.idProperty (property/properties that define record ID)

    @author Greg Varsanyi
    ###
    class RestList extends List

      ###
      @property [number] The number of REST requests pending
      ###
      restPending: 0

      ###
      Query list endpoint for raw data

      Option used:
      - .options.endpoint.url

      @param [Object] query_parameters (optional) Query string arguments
      @param [function] callback (optional) Callback function with signiture:
        (err, raw_response) ->
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [ValueError] No .options.endpoint.url
      @throw [TypeError] .options.endpoint.url is not a string

      @return [$HttpPromise] Promise returned by $http
      ###
      restGetRaw: (query_parameters, callback) ->
        if typeof query_parameters is 'function'
          callback = query_parameters
          query_parameters = null

        list = @

        unless (endpoint = list.options.endpoint) and (url = endpoint.url) and
        typeof url is 'string'
          error.Type {'options.endpoint.url': url, required: 'string'}

        if query_parameters
          parts = for k, v of query_parameters
            encodeURIComponent(k) + '=' + encodeURIComponent v
          if parts.length
            url += (if url.indexOf('?') > -1 then '&' else '?') + parts.join '&'

        define_value list, REST_PENDING, list[REST_PENDING] + 1, false, true
        restUtils.wrapPromise $http.get(url), (err, result) ->
          define_value list, REST_PENDING, list[REST_PENDING] - 1, false, true
          callback err, result

      ###
      Query list endpoint for records

      Options that may be used:
      - .options.endpoint.responseProperty (array of records in list response)
      - .options.endpoint.url (url for endpoint)
      - .options.record.class (class reference for record objects)
      - .options.record.idProperty (property/properties that define record ID)

      @param [Object] query_parameters (optional) Query string arguments
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      @option record_list [Array] insert (optional) List of inserted records
      @option record_list [Array] update (optional) List of updated records
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [ValueError] No .options.endpoint.url
      @throw [TypeError] .options.endpoint.url is not a string

      @return [$HttpPromise] Promise returned by $http
      ###
      restLoad: (query_parameters, callback) ->
        if typeof query_parameters is 'function'
          callback = query_parameters
          query_parameters = null

        list = @

        list.restGetRaw query_parameters, (err, raw_response) ->
          unless err
            try
              data = RestList::__getResponseArray.call list, raw_response.data
              record_list = list.push data..., true
            catch _err
              err = _err
          callback? err, record_list, raw_response

      ###
      Save record(s)

      Options that may be used:
      - .options.endpoint.url (url for endpoint)
      - .options.endpoint.bulkSave = true/'PUT' or 'POST'
      - .options.record.idProperty (property/properties that define record ID)
      - .options.record.endpoint.url (url for endpoint with ID)

      @param [Record/number] records... 1 or more records or ID's to save
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      @option record_list [Array] insert (optional) List of new records
      @option record_list [Array] update (optional) List of updated records
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [MissingArgumentError] No record to save
      @throw [ValueError] No .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in
      @throw [TypeError] .options(.record).endpoint.url is not a string

      @return [HttpPromise] Promise or chained promises returned by $http.put or
      $http.post
      ###
      restSave: (records..., callback) ->
        RestList::__writeBack.call @, 1, records..., callback


      ###
      Delete record(s)

      Options that may be used:
      - .options.endpoint.url (url for endpoint)
      - .options.endpoint.bulkDelete
      - .options.record.idProperty (property/properties that define record ID)
      - .options.record.endpoint.url (url for endpoint with ID)

      @param [Record/number] records... 1 or more records or ID's to delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->
      @option record_list [Array] insert (optional) List of new records
      @option record_list [Array] update (optional) List of updated records
      @option raw_response [HttpError] error (optional) errorous response info
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [MissingArgumentError] No record to delete
      @throw [ValueError] No .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in
      @throw [TypeError] .options(.record).endpoint.url is not a string

      @return [HttpPromise] Promise or chained promises returned by $http.delete
      ###
      restDelete: (records..., callback) ->
        RestList::__writeBack.call @, 0, records..., callback


      ###
      ID the array in list GET response

      Uses .options.endpoint.responseProperty or attempts to create it based on
      provided data. Returns identified array or throws an error.

      Uses option:
      - .options.endpoint.responseProperty (defines which property of response
      JSON object is the record array)

      @param [Object] data Response object from REST API for list GET request

      @throw [ValueError] Array not found in data

      @return [Array] List of raw records (property of data or data itself)
      ###
      __getResponseArray: (data) ->
        endpoint_options = @options.endpoint
        key = 'responseProperty'

        if typeof endpoint_options[key] is 'undefined'
          # auto-identify options.endpoint.responseProperty
          if Array.isArray data
            endpoint_options[key] = null # response is top level Array

          for k, v of data when Array.isArray v
            endpoint_options[key] = k # found the Array in response

        if endpoint_options[key]?
          data = data[endpoint_options[key]]

        unless data instanceof Array
          error.Value
            'options.endpoint.responseProperty': undefined,
            description: 'array type property in response is not found or ' +
                         'unspecified'

        data


      ###
      PUT, POST and DELETE logic

      Options that may be used:
      - .options.endpoint.bulkDelete
      - .options.endpoint.bulkSave = true/'PUT' or 'POST'
      - .options.endpoint.url

      @param [boolean] save_type Save (PUT/POST) e.g. not delete
      @param [Record] records... Record or list of records to save/delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->

      @throw [MissingArgumentError] No record to delete
      @throw [ValueError] No .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in
      @throw [TypeError] .options(.record).endpoint.url is not a string

      @return [$HttpPromise] Promise or chained promises of the HTTP action(s)
      ###
      __writeBack: (save_type, records..., callback) ->
        unless callback and typeof callback is 'function'
          records.push(callback) if callback
          callback = null

        list = @

        unique_record_map = {}
        for record, i in records
          unless typeof record is 'object'
            records[i] = record = list.map[record]

          orig_rec = record
          unless (record = list.map[id = record?._id])
            error.Key {key: orig_rec, description: 'no such element'}

          if unique_record_map[id]
            error.Value {id, description: 'not unique'}

          unique_record_map[id] = record

        unless records.length
          error.MissingArgument {name: 'record', argument: 1}

        endpoint_options = list.options.endpoint or {}

        # api has collection/bulk support
        if save_type and endpoint_options.bulkSave
          bulk_method = String(endpoint_options.bulkSave).toLowerCase()
          bulk_method = 'put' unless bulk_method is 'post'
        else if not save_type and endpoint_options.bulkDelete
          bulk_method = 'delete'
        if bulk_method
          unless endpoint_options.url
            error.Value {'options.endpoint.url': undefined}
          unless typeof endpoint_options.url is 'string'
            error.Type
              'options.endpoint.url': endpoint_options.url
              required:               'string'

          data = for record in records
            if save_type
              record._entity()
            else
              record._id

          args = [endpoint_options.url]
          args.push(data) unless bulk_method is 'delete'
          list[REST_PENDING] += 1
          promise = $http[bulk_method] args...
          return restUtils.wrapPromise promise, (err, raw_response) ->
            list[REST_PENDING] -= 1
            unless err
              if save_type
                record_list = list.push raw_response.data..., true
              else
                record_list = list.cut.apply list, records
            callback? err, record_list, raw_response


        # api has no collection/bulk support
        results = {}
        finished = (err) ->
          raw_responses = Array::slice.call arguments, 1
          callback? err, results, raw_responses...

        iteration = (record) ->
          id     = record._id
          method = 'delete'
          url    = list.options.record.endpoint?.url
          if save_type
            method = 'put'
            # TODO: cover new records saving
            #             unless (id = record._id) and id isnt 'pseudo'
            #               method = 'post'
            #               id = null
            #               url = list.options?.endpoint?.url

          unless url
            error.Value {'options.endpoint.url': undefined}

          unless typeof url is 'string'
            error.Type {'options.record.endpoint.url': url, required: 'string'}

          # if id?
          url = url.replace '<id>', id

          args = [url]
          args.push(record._entity()) if save_type
          list[REST_PENDING] += 1
          promise = $http[method](args...)
          restUtils.wrapPromise promise, (err, raw_response) ->
            list[REST_PENDING] -= 1
            unless err
              if save_type
                for k, v of list.push raw_response.data, true
                  results[k] = (results[k] or 0) + v
              else
                results.cut = (results.cut or 0) + list.cut(record).cut.length
            return

        restUtils.asyncSquash records, iteration, finished
]
