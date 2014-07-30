
app.service 'ksc.restUtils', [
  '$q', 'ksc.errors',
  ($q, errors) ->

    restUtils =
      asyncSquash: (records, done_callback, iteration_fn) ->
        count      = 0
        error_list = []
        len        = records.length
        results    = []

        iteration_callback = (err, result) ->
          {data, status, headers, config} = result
          count += 1
          error_list.push(err) if err?
          results.push {error: err, data, status, headers, config}

          if count is len and done_callback
            error = null
            if error_list.length is 1
              error = error_list[0]
            else if error_list.length
              error = error_list

            done_callback error, results...

        promises = for record in records
          restUtils.wrapPromise iteration_fn(record), iteration_callback

        if promises.length < 2
          return promises[0]
        $q.all promises # chained promises


      wrapPromise: (promise, callback) ->
        success_fn = (result) ->
          wrap = ({data, status, headers, config} = result)
          callback null, wrap

        error_fn = (result) ->
          wrap = ({data, status, headers, config} = result)
          err = new errors.Http result
          wrap.error = err
          callback err, wrap

        promise.then success_fn, error_fn

        promise
]
