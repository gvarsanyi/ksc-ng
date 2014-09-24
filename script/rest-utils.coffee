
app.service 'ksc.restUtils', [
  '$q', 'ksc.error',
  ($q, error) ->

    ###
    Rest/XHR call related utilities

    @author Greg Varsanyi
    ###
    class RestUtils

      ###
      Squash multiple requests into a single one

      @param [Array] list of values that will be used as argument #1 and passed
        to iteration_fn in each iteration. Number of items defines number of
        iterations.
      @param [function] iteration_fn function to be called for each iteration.
        Signiture is: `(iteration_data_set) ->` and should return a Promise
      @param [function] done_callback function to be called when chained promise
        gets resolved

      @return [Promise] chained promises of all requests
      ###
      @asyncSquash: (iteration_data_sets, iteration_fn, done_callback) ->
        count      = 0
        error_list = []
        len        = iteration_data_sets.length
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

        promises = for iteration_data_set in iteration_data_sets
          RestUtils.wrapPromise iteration_fn(iteration_data_set),
                                 iteration_callback

        if promises.length < 2
          return promises[0]
        $q.all promises # chained promises

      ###
      Add listeners to promise so that standard callback functions with
      signiture `(err, results...) ->` can be called when the
      promise gets resolved.

      On callback function, argument `err` is null on no errors or an instance
      of Error if there was an error.
      `result` is the raw result of the request, similar to what $http methods
      return: {data, status, headers, config}

      @param [Promise] promise $q promise to be wrapped
      @param [function] callback response function

      @return [Promise] the provided promise object reference
      ###
      @wrapPromise: (promise, callback) ->
        success_fn = (result) ->
          wrap = ({data, status, headers, config} = result)
          callback null, wrap

        error_fn = (result) ->
          wrap = ({data, status, headers, config} = result)
          err = new error.type.Http result
          wrap.error = err
          callback err, wrap

        promise.then success_fn, error_fn

        promise

    # returns restUtils
]
