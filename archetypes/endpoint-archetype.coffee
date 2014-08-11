
app.service 'ksc.endpointArchetype', [
  'ksc.endpointArchetypeFactory',
  (endpointArchetypeFactory) ->

    service = endpointArchetypeFactory()

    service.restLoad()

    service
]
