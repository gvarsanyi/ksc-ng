
main.factory 'kareo.restUtils', ->
  wrapPromise: (rest_node, promise, callback) ->
    load_count_increment = ->
      rest_node[load_key] = (rest_node[load_key] or 0) + 1
      return

    load_count_decrement = ->
      rest_node[load_key] -= 1
      if rest_node[load_key] is 0
        delete rest_node[load_key]
      return

    load_key = (if rest_node instanceof Array then '' else '_') + 'restLoading'

    load_count_increment rest_node

    promise.success (data, status, headers, config) ->
      load_count_decrement rest_node
      callback? null, {data, status, headers, config}

    promise.error (data, status, headers, config) ->
      load_count_decrement rest_node
      err = new Error 'HTTP' + status + ': ' + config.method + ' ' + config.url
      callback? err, {error: err, data, status, headers, config}
