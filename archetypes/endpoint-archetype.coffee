
example ?= angular.module 'example', ['ksc']

example.service 'ksc.endpointArchetype', [
  'ksc.endpointArchetypeFactory',
  (endpointArchetypeFactory) ->

    service = endpointArchetypeFactory()

    service.restLoad()

    service
]
