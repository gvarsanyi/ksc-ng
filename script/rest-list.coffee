
app.factory 'ksc.RestList', [
  '$http', '$q', 'ksc.List', 'ksc.batchLoaderRegistry', 'ksc.error',
  'ksc.restUtils', 'ksc.utils',
  ($http, $q, List, batchLoaderRegistry, error,
   restUtils, utils) ->

    REST_PENDING = 'restPending'
    PRIMARY_ID   = '_primaryId'

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

        define_value list, REST_PENDING, list[REST_PENDING] + 1, false, true

        unless promise = batchLoaderRegistry.get url, query_parameters
          if query_parameters
            parts = for k, v of query_parameters
              encodeURIComponent(k) + '=' + encodeURIComponent v
            if parts.length
              url += (if url.indexOf('?') > -1 then '&' else '?') +
                     parts.join '&'

          promise = $http.get url

        restUtils.wrapPromise promise, (err, result) ->
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
          pseudo_id = null
          uid = 'id:' + (id = record?._id)
          unless (id = record?._id)?
            pseudo_id = record?._pseudo
            uid = 'pseudo:' + pseudo_id
          else if record[PRIMARY_ID]?
            uid = 'id:' + record[PRIMARY_ID]

          if save_type
            record = (pseudo_id and list.pseudo[pseudo_id]) or list.map[id]
            unless record
              error.Key {key: orig_rec, description: 'no such record on list'}
          else unless record = list.map[id]
            error.Key {key: orig_rec, description: 'no such record on map'}

          if unique_record_map[uid]
            error.Value {uid, description: 'not unique'}
          unique_record_map[uid] = record

        unless records.length
          error.MissingArgument {name: 'record', argument: 1}

        endpoint_options = list.options.endpoint or {}

        if save_type and endpoint_options.bulkSave
          bulk_method = String(endpoint_options.bulkSave).toLowerCase()
          bulk_method = 'put' unless bulk_method is 'post'
        else if not save_type and endpoint_options.bulkDelete
          bulk_method = 'delete'

        related_records = (record) ->
          unless id = record[PRIMARY_ID]
            return [record]
          (item for item in list when item[PRIMARY_ID] is id)

        bulk_update = (records, updates, next) ->
          promises = []
          replacable = []
          for record, i in records
            if id = record[PRIMARY_ID]
              query_parameters = {}
              query_parameters[record._options.idProperty[0]] = id
              promises.push list.restLoad query_parameters
            else
              replacable.push [record, updates[i]]

          if replacable.length
            list.events.halt()
            changed = []
            tmp_listener_unsubscribe = list.events.on '1#!update', (info) ->
              changed.push info.action.update[0]
            try
              for replace in replacable
                [record, data] = replace
                record._replace data
            finally
              tmp_listener_unsubscribe()
              list.events.unhalt()
            if changed.length
              list.events.emit 'update', {node: list, action: update: changed}

          if promises.length
            promise = $q.all promises
            promise.then next, next
          else
            next()

        # ---BULK--- api has collection/bulk support
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
              unless (id = record[PRIMARY_ID])?
                id = record._id
              id

          args = [endpoint_options.url]
          args.push(data) unless bulk_method is 'delete'
          list[REST_PENDING] += 1
          promise = $http[bulk_method] args...
          return restUtils.wrapPromise promise, (err, raw_response) ->
            list[REST_PENDING] -= 1
            ready = ->
              callback? err, related, raw_response
            related = []
            for record in records
              related.push related_records(record)...
            unless err
              if save_type
                bulk_update records, raw_response.data, ready
              else
                list.cut.apply list, related
                ready()
            ready()
        # ---EOF BULK---

        # api has NO collection/bulk support
        record_list = []
        delayed_cb_args = pending_refresh = null
        finished = (err) ->
          raw_responses = Array::slice.call arguments, 1
          delayed_cb_args = [err, record_list, raw_responses...]
          unless pending_refresh
            callback? delayed_cb_args...
            delayed_cb_args = null

        iteration = (record) ->
          unless (id = record[PRIMARY_ID])?
            id = record._id
          method = 'delete'
          url    = list.options.record.endpoint?.url
          if save_type
            method = 'put'
            if record._pseudo
              method = 'post'
              id = null
              url = list.options.endpoint?.url

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
            related = related_records record
            unless err
              if save_type
                pending_refresh = (pending_refresh or 0) + 1
                bulk_update [record], [raw_response.data], ->
                  pending_refresh -= 1
                  if delayed_cb_args
                    callback? delayed_cb_args...
              else
                list.cut related...
            record_list.push related...
            return

        restUtils.asyncSquash records, iteration, finished
]
