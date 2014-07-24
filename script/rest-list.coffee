
app.factory 'ksc.RestList', [
  '$http', 'ksc.List', 'ksc.RestUtils',
  ($http, List, RestUtils) ->

    REST_PENDING = 'restPending'


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

    @author Greg Varsanyi <greg.varsanyi@kareo.com>
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
      @option raw_response [Error] error (optional) $http error
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [Error] No .options.endpoint.url

      @return [$HttpPromise] Promise returned by $http
      ###
      restGetRaw: (query_parameters, callback) ->
        if typeof query_parameters is 'function'
          callback = query_parameters
          query_parameters = null

        list = @

        unless url = list.options.endpoint?.url
          throw new Error 'Could not identify endpoint url'

        if query_parameters
          parts = for k, v of query_parameters
            encodeURIComponent(k) + '=' + encodeURIComponent v
          if parts.length
            url += (if url.indexOf('?') > -1 then '&' else '?') + parts.join '&'

        list[REST_PENDING] += 1
        RestUtils.wrapPromise $http.get(url), (err, result) ->
          list[REST_PENDING] -= 1
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
      @option raw_response [Error] error (optional) $http error
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

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
      @option raw_response [Error] error (optional) $http error
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [Error] No record to save
      @throw [Error] Non-unique record was passed in
      @throw [Error] Missing options.endpoint.url or options.record.endpoint.url

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
      @option raw_response [Error] error (optional) $http error
      @option raw_response [Object] data HTTP response data in JSON
      @option raw_response [number] status HTTP rsponse status
      @option raw_response [Object] headers HTTP response headers
      @option raw_response [Object] config $http request configuration

      @throw [Error] No record to delete
      @throw [Error] Non-unique record was passed in
      @throw [Error] Missing options.endpoint.url or options.record.endpoint.url

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

      @throw [Error] Array not found in data

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
          throw new Error 'Could not identify options.endpoint.responseProperty'

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

      @throw [Error] No record to save/delete
      @throw [Error] Non-unique record was passed in
      @throw [Error] Missing options.endpoint.url or options.record.endpoint.url

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

          orig_item = record
          unless (record = list.map[id = record?._id])
            throw new Error 'record is not in the list: ' + orig_item

          if unique_record_map[id]
            throw new Error 'Record/ID is not unique: ' + id

          unique_record_map[id] = record

        unless records.length
          throw new Error 'No records to send to the REST interface'

        endpoint_options = list.options.endpoint or {}

        # api has collection/bulk support
        if save_type and endpoint_options.bulkSave
          bulk_method = String(endpoint_options.bulkSave).toLowerCase()
          bulk_method = 'put' unless bulk_method is 'post'
        else if not save_type and endpoint_options.bulkDelete
          bulk_method = 'delete'
        if bulk_method
          unless endpoint_options.url
            throw new Error 'Could not identify endpoint url'

          if save_type
            data = (record._entity() for record in records)
          else
            data = for record in records
              if record._primaryId? then record._primaryId else record._id
          args = [endpoint_options.url]
          args.push(data) unless bulk_method is 'delete'
          list[REST_PENDING] += 1
          promise = $http[bulk_method] args...
          return RestUtils.wrapPromise promise, (err, raw_response) ->
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

        RestUtils.asyncSquash records, finished, (record) ->
          id     = if record._primaryId? then record._primaryId else record._id
          method = 'delete'
          url    = list.options.record?.endpoint?.url
          if save_type
            method = 'put'
            # TODO: cover new records saving
            #             unless (id = record._id) and id isnt 'pseudo'
            #               method = 'post'
            #               id = null
            #               url = list.options?.endpoint?.url

          unless url
            throw new Error 'Could not identify endpoint url'

          # if id?
          url = url.replace '<id>', id

          args = [url]
          args.push(record._entity()) if save_type
          list[REST_PENDING] += 1
          promise = $http[method](args...)
          RestUtils.wrapPromise promise, (err, raw_response) ->
            list[REST_PENDING] -= 1
            unless err
              if save_type
                for k, v of list.push raw_response.data, true
                  results[k] = (results[k] or 0) + v
              else
                results.cut = (results.cut or 0) + list.cut(record).cut.length
            return
]
