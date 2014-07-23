
app.factory 'ksc.RestUtils', [
  '$q',
  ($q) ->

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
          iteration_fn record, iteration_callback

        if promises.length < 2
          return promises[0]
        $q.all promises # chained promises


      @wrapPromise: (promise, rest_node, callback) ->
        if typeof rest_node is 'function'
          callback = rest_node
          rest_node = null

        prefix = if rest_node instanceof Array then '' else '_'
        load_key = prefix + 'restLoading'

        if rest_node
          rest_node[load_key] = (rest_node[load_key] or 0) + 1

        load_count_decrement = ->
          if rest_node
            rest_node[load_key] -= 1
            if rest_node[load_key] is 0
              delete rest_node[load_key]

        success_fn = (result) ->
          load_count_decrement rest_node
          wrap = ({data, status, headers, config} = result)
          callback? null, wrap

        error_fn = (result) ->
          load_count_decrement rest_node
          wrap = ({data, status, headers, config} = result)
          err = new Error 'HTTP' + status + ': ' +
                          config.method + ' ' + config.url
          wrap.error = err
          callback? err, wrap

        promise.then success_fn, error_fn

        promise
]
