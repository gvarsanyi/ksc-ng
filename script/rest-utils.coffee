
app.factory 'ksc.RestUtils', [
  '$q', 'ksc.Errors',
  ($q, Errors) ->

    class RestUtils

      @asyncSquash: (records, done_callback, iteration_fn) ->
        count   = 0
        errors  = []
        len     = records.length
        results = []

        iteration_callback = (err, result) ->
          {data, status, headers, config} = result
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
          RestUtils.wrapPromise iteration_fn(record), iteration_callback

        if promises.length < 2
          return promises[0]
        $q.all promises # chained promises


      @wrapPromise: (promise, callback) ->
        success_fn = (result) ->
          wrap = ({data, status, headers, config} = result)
          callback null, wrap

        error_fn = (result) ->
          wrap = ({data, status, headers, config} = result)
          err = new Errors.Http result
          wrap.error = err
          callback err, wrap

        promise.then success_fn, error_fn

        promise
]
