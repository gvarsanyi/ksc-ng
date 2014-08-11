
app.service 'ksc.bootstrapArchetype', [
  'ksc.BatchLoader',
  (BatchLoader) ->

    bootstrap = new BatchLoader '/api/Bootstrap',
      Test:  '/api/Test'
      Other: '/api/Other'

    # NOTE: there might be a better way to trigger flush right after the
    # controllers are created and first load requests collected
    setTimeout ->
      bootstrap.flush()
      bootstrap.open = false
    , 5

    bootstrap
]
