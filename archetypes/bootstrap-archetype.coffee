
example ?= angular.module 'example', ['ksc']

example.service 'ksc.bootstrapArchetype', [
  'ksc.BatchLoader',
  (BatchLoader) ->

    bootstrap = new BatchLoader '/api/Bootstrap',
      Test:  '/api/Test'
      Other: '/api/Other'

    setTimeout ->
      bootstrap.open = false # this triggers loading - don't call .flush()
    , 5

    bootstrap
]
