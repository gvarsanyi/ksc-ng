
ksc.factory 'ksc.RestList', [
  '$http', '$q', 'ksc.List', 'ksc.batchLoaderRegistry', 'ksc.error',
  'ksc.restUtil', 'ksc.util',
  ($http, $q, List, batchLoaderRegistry, error,
   restUtil, util) ->

    REST_CACHE   = 'restCache'
    REST_PENDING = 'restPending'
    PRIMARY_ID   = '_primaryId'

    define_value = util.defineValue

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
    - .options.cache (full cache - use if the entire list is loaded)
    - .options.endpoint.bulkDelete (delete 2+ records in 1 request)
    - .options.endpoint.bulkSavel (save 2+ records in 1 request)
    - .options.endpoint.responseProperty (array of records in list response)
    - .options.endpoint.url (url for endpoint)
    - .options.record.endpoint.url (url for endpoint with record ID)
    - .options.reloadOnUpdate (force reload on save instead of picking up
      response of POST or PUT request)

    Options that may be used by methods of ksc.List
    - .options.record.class (class reference for record objects)
    - .idProperty (property/properties that define record ID)

    @author Greg Varsanyi
    ###
    class RestList extends List
      # @property [object] load promise used if .options.cache is set
      restCache: undefined

      ###
      @property [number] The number of REST requests pending
      ###
      restPending: 0


      ###
      A proxy constructor, see {List#constructor} for all logic.

      Checks if .idProperty is set (required for RestList)

      @throw [MissingArgumentError] if idProperty is not set

      @return [Array] native arrray decorated with List and RestList properties
      ###
      constructor: ->
        list = super
        unless list.idProperty?
          error.MissingArgument required: 'idProperty is mandatory for RestList'
        return list

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

      @return [Promise] Promise returned by $http
      ###
      restGetRaw: (query_parameters, callback) ->
        if typeof query_parameters is 'function'
          callback = query_parameters
          query_parameters = null

        list = @

        unless (endpoint = list.options.endpoint) and (url = endpoint.url) and
        typeof url is 'string'
          error.Type {'options.endpoint.url': url, required: 'string'}

        define_value list, REST_PENDING, list[REST_PENDING] + 1, 0, 1

        unless promise = batchLoaderRegistry.get url, query_parameters
          if query_parameters
            parts = for k, v of query_parameters
              encodeURIComponent(k) + '=' + encodeURIComponent v
            if parts.length
              url += (if url.indexOf('?') > -1 then '&' else '?') +
                     parts.join '&'

          promise = $http.get url

        restUtil.wrapPromise promise, (err, result) ->
          define_value list, REST_PENDING, list[REST_PENDING] - 1, 0, 1
          callback err, result

      ###
      Query list endpoint for records

      Options that may be used:
      - .options.cache (full cache - use if the entire list is loaded)
      - .options.endpoint.responseProperty (array of records in list response)
      - .options.endpoint.url (url for endpoint)
      - .options.record.class (class reference for record objects)
      - .idProperty (property/properties that define record ID)

      @param [boolean] force_load (optional) Request disregarding cache
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

      @return [Promise] Promise returned by $http
      ###
      restLoad: (force_load, query_parameters, callback) ->
        unless typeof force_load is 'boolean'
          callback         = query_parameters
          query_parameters = force_load
          force_load       = null

        if typeof query_parameters is 'function'
          callback         = query_parameters
          query_parameters = null

        list    = @
        options = list.options

        http_get = ->
          list.restGetRaw query_parameters, (err, raw_response) ->
            unless err
              try
                data = RestList.getResponseArray list, raw_response.data
                record_list = list.push data..., true
              catch _err
                err = _err
            callback? err, record_list, raw_response

        if not options.cache or not list.restCache or force_load
          define_value list, 'restCache', http_get(), 0, 1
        else if callback
          restUtil.wrapPromise list.restCache, callback

        list.restCache

      ###
      Save record(s)

      Uses {RestList#writeBack}

      Records may be map IDs from list.idMap or the record instances

      Records must be unique

      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be updated

      Options that may be used:
      - .options.endpoint.url (url for endpoint)
      - .options.endpoint.bulkSave = true/'PUT' or 'POST'
      - .options.record.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)
      - .idProperty (property/properties that define record ID)

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
      @throw [ValueError] Invalid .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in

      @return [HttpPromise] Promise or chained promises returned by $http.put or
      $http.post
      ###
      restSave: (records..., callback) ->
        RestList.writeBack @, 1, records, callback


      ###
      Delete record(s)

      Uses {RestList#writeBack}

      Records may be map IDs from list.idMap or the record instances

      Records must be unique

      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be deleted

      Options that may be used:
      - .options.endpoint.url (url for endpoint)
      - .options.endpoint.bulkDelete
      - .options.record.endpoint.url (url for endpoint with ID)
      - .idProperty (property/properties that define record ID)

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
      @throw [ValueError] Invalid .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in

      @return [HttpPromise] Promise or chained promises returned by $http.delete
      ###
      restDelete: (records..., callback) ->
        RestList.writeBack @, 0, records, callback


      ###
      ID the array in list GET response

      Uses .options.endpoint.responseProperty or attempts to create it based on
      provided data. Returns identified array or throws an error.

      Uses option:
      - .options.endpoint.responseProperty (defines which property of response
      JSON object is the record array)

      @param [Array] list Array generated by {RestList}
      @param [Object] data Response object from REST API for list GET request

      @throw [ValueError] Array not found in data

      @return [Array] List of raw records (property of data or data itself)
      ###
      @getResponseArray: (list, data) ->
        endpoint_options = list.options.endpoint
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
      Find records with identical ._primaryId and return them along with the
      checked record (or just return a single-element array with the checked
      record if it does not have ._primaryId)

      @param [Array] list Array generated by {RestList}
      @param [Record] record Record to get related records for

      @return [Array] All records on the list with identical ._primaryId
      ###
      @relatedRecords: (list, record) ->
        unless (id = record[PRIMARY_ID])?
          return [record]
        (item for item in list when item[PRIMARY_ID] is id)

      ###
      Take the response as update value unless
      - record has composite id
      - .options.reloadOnUpdate is truthy

      Option that may be used:
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)

      @param [Array] list Array generated by {RestList}
      @param [Array] records Records that were saved
      @param [Array] updates Related responses of PUT/POST request(s)
      @param [function] next callback function - called when updates are done

      @return [undefined]
      ###
      @updateOnSave: (list, records, updates, next) ->
        promises = []
        replacable = []
        for record, i in records
          if (primary_id = record[PRIMARY_ID])? or list.options.reloadOnUpdate
            query_parameters = {}
            key = list.idProperty
            if primary_id
              query_parameters[key[0]] = primary_id
            else
              query_parameters[key] = record._id
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
        return

      ###
      PUT, POST and DELETE joint logic

      After error checks, it will pass the request to {RestList#writeBulk} or
      {RestList#writeSolo} depending on what the endpoint supports

      Records may be map IDs from list.idMap or the record instances

      Records must be unique

      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be affected

      Options that may be used:
      - .options.endpoint.bulkDelete
      - .options.endpoint.bulkSave = true/'PUT' or 'POST'
      - .options.endpoint.url
      - .options.record.idProperty (property/properties that define record ID)
      - .options.record.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)

      @param [Array] list Array generated by {RestList}
      @param [boolean] save_type Save (PUT/POST) e.g. not delete
      @param [Array] records List of records to save/delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->

      @throw [MissingArgumentError] No record to save/delete
      @throw [ValueError] Invalid .options(.record).endpoint.url
      @throw [ValueError] Non-unique record was passed in

      @return [Promise] Promise or chained promises of the HTTP action(s)
      ###
      @writeBack: (list, save_type, records, callback) ->
        unless callback and typeof callback is 'function'
          records.push(callback) if callback
          callback = null

        unique_record_map = {}
        for record, i in records
          unless util.isObject record
            records[i] = record = list.idMap[record]

          orig_rec = record
          pseudo_id = null
          uid = 'id:' + (id = record?._id)
          unless (id = record?._id)?
            pseudo_id = record?._pseudo
            uid = 'pseudo:' + pseudo_id
          else if record[PRIMARY_ID]?
            uid = 'id:' + record[PRIMARY_ID]

          if save_type
            record = (pseudo_id and list.pseudoMap[pseudo_id]) or list.idMap[id]
            unless record
              error.Key {key: orig_rec, description: 'no such record on list'}
          else unless record = list.idMap[id]
            error.Key {key: orig_rec, description: 'no such record on .idMap'}

          if unique_record_map[uid]
            error.Value {uid, description: 'not unique'}
          unique_record_map[uid] = record

        unless records.length
          error.MissingArgument {name: 'record', argument: 1}

        endpoint_options = list.options.endpoint or {}

        if save_type and endpoint_options.bulkSave
          bulk_method = String(endpoint_options.bulkSave).toLowerCase()
          bulk_method = 'put' unless bulk_method is 'post'
          RestList.writeBulk list, bulk_method, records, callback
        else if not save_type and endpoint_options.bulkDelete
          RestList.writeBulk list, 'delete', records, callback
        else
          RestList.writeSolo list, save_type, records, callback

      ###
      PUT, POST or DELETE on .options.endpoint.url - joint operation, single XHR
      thread

      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be affected

      Options that may be used:
      - .options.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)

      @param [Array] list Array generated by {RestList}
      @param [string] method 'put', 'post' or 'delete'
      @param [Array] records List of records to save/delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->

      @throw [ValueError] Invalid .options.record.endpoint.url

      @return [Promise] Promise of HTTP action
      ###
      @writeBulk: (list, method, records, callback) ->
        unless (url = list.options.endpoint.url) and typeof url is 'string'
          error.Type {'options.endpoint.url': url, required: 'string'}

        saving = method isnt 'delete'

        data = for record in records
          if saving
            record._entity()
          else
            unless (id = record[PRIMARY_ID])?
              id = record._id
            id

        args = [url]
        args.push(data) if saving
        list[REST_PENDING] += 1
        promise = $http[method] args...
        return restUtil.wrapPromise promise, (err, raw_response) ->
          list[REST_PENDING] -= 1
          ready = ->
            callback? err, related, raw_response
          related = []
          for record in records
            related.push RestList.relatedRecords(list, record)...
          unless err
            if saving
              RestList.updateOnSave list, records, raw_response.data, ready
            else
              list.cut.apply list, related
              ready()
          ready()

      ###
      PUT, POST or DELETE on .options.record.endpoint.url - separate XHR threads

      If records have composite IDs (see: {Record#setId}), ._primaryId will be
      used, all records with identical ._primaryId will be affected

      Options that may be used:
      - .options.record.endpoint.url (url for endpoint with ID)
      - .options.reloadOnUpdate (force reload on save instead of picking up
        response of POST or PUT request)

      @param [Array] list Array generated by {RestList}
      @param [boolean] save_type Save (PUT/POST) e.g. not delete
      @param [Array] records List of records to save/delete
      @param [function] callback (optional) Callback function with signiture:
        (err, record_list, raw_response) ->

      @throw [ValueError] Invalid .options.record.endpoint.url

      @return [Promise] Promise or chained promises of the HTTP action(s)
      ###
      @writeSolo: (list, save_type, records, callback) ->
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

          unless url and typeof url is 'string'
            error.Value {'options.record.endpoint.url': url, required: 'string'}

          # if id?
          url = url.replace '<id>', id

          args = [url]
          args.push(record._entity()) if save_type
          list[REST_PENDING] += 1
          promise = $http[method](args...)
          restUtil.wrapPromise promise, (err, raw_response) ->
            list[REST_PENDING] -= 1
            related = RestList.relatedRecords list, record
            unless err
              if save_type
                pending_refresh = (pending_refresh or 0) + 1
                RestList.updateOnSave list, [record], [raw_response.data], ->
                  pending_refresh -= 1
                  if delayed_cb_args
                    callback? delayed_cb_args...
              else
                list.cut related...
            record_list.push related...
            return

        restUtil.asyncSquash records, iteration, finished
]
