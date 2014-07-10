
main.factory 'kareo.RestList', [
  '$http', 'kareo.List', 'kareo.restUtils',
  ($http, List, restUtils) ->

    async_squash = (records, done_callback, iteration_fn) ->
      count   = 0
      errors  = []
      len     = records.length
      results = []

      iteration_callback = (err, data, status, headers, config) ->
        count += 1
        errors.push(err) if err?
        results.push {error: err, data, status, headers, config}

        if count is len and done_callback
          error = null
          if errors.length is 1
            error = errors[0]
          else if errors.length
            error = errors

          done_callback error, results...

      promises = for record in records
        iteration_fn record, iteration_callback

      if promises.length < 2
        return promises[0]
      promises

    # @restListProperty
    upsert = (list, data) ->
      if typeof list.restListProperty is 'undefined'
        # auto-identify restListProperty
        if data instaceof Array
          list.restListProperty = null # response data is top level Array
        else
          for k, v of data when v instaceof Array
            list.restListProperty = k # found the Array in response
            break

      list_property = list.restListProperty

      unless data[list_property] instanceof Array
        throw new Error 'Could not identify restListProperty'

      src = if list_property then data[list_property] else data
      list.push src..., true


    # @restBulkDelete
    # @restBulkSave=(true==PUT)|POST
    # @restUrl
    write_back = (save_type, list, records..., callback) ->
      unless callback and typeof callback is 'function'
        records.push(callback) if callback
        callback = null

      url = list.restUrl

      # api has collection/bulk support
      if save_type and bulk_method = String(list.restBulkSave).toLowerCase()
        bulk_method = 'put' unless bulk_method is 'post'
      else if not save_type and list.restBulkDelete
        bulk_method = 'delete'
      if bulk_method
        if save_type
          data = (record.entity() for record in records)
        else
          data = (record.id for record in records)
        promise = $http[bulk_method] url, data
        return restUtils.wrapPromise list, promise, (err, raw_response) ->
          unless err
            if save_type
              record_list = upsert list, raw_response.data
            else
              record_list = list.cut records...
          callback? err, record_list, raw_response


      # api has no collection/bulk support
      results = {}
      finished = (err, raw_responses...) ->
        callback? err, results, raw_responses...

      async_squash records, finished, (record, iteration_callback) ->
        method = 'delete'
        if save_type
          method = 'post'
          if (id = record.id) and id isnt 'pseudo'
            method = 'put'
            if typeof id is 'string' # handle composite id
              id = id.split('-')[0]
            url += '/' unless url.lastIndexOf('/') is url.length - 1
            url += id

        args = [url]
        args.push(record.entity()) if save_type
        promise = $http[method](args...)
        restUtils.wrapPromise list, promise, (err, raw_response) ->
          unless err
            if save_type
              for k, v of list.push raw_response.data
                results[k] = (results[k] or 0) + v
            else
              results.cut = (results.cut or 0) + (list.cut record)?.cut or 0
          iteration_callback err, raw_response


    class RestList extends List
      # @restUrl
      restGetRaw: (query_parameters, callback) ->
        if typeof query_parameters is 'function'
          callback = query_parameters
          query_parameters = null

        url = @restUrl
        if query_parameters
          parts = for k, v of options
            encodeURIComponent(k) + '=' + encodeURIComponent v
          if parts.length
            url += (if url.indexOf('?') > -1 then '&' else '?') + parts.join '&'

        restUtils.wrapPromise @, $http.get(url), callback

      # [@restListProperty]
      # @restUrl
      restLoad: (query_parameters, callback) ->
        if typeof query_parameters is 'function'
          callback = query_parameters
          query_parameters = null

        list = @

        @restGetRaw query_parameters, (err, raw_response) ->
          unless err
            record_list = upsert list, raw_response.data
          callback? err, record_list, raw_response

      # [@restListProperty]
      # @restBulkSave=(true==PUT)|POST
      # @restUrl
      restSave: (records..., callback) ->
        write_back 1, @, records..., callback

      # @restBulkDelete
      # @restUrl
      restDelete: (records..., callback) ->
        write_back 0, @, records..., callback
]
