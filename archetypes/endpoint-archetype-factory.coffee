
app.factory 'ksc.EndpointArchetypeFactory', [
  'ksc.EditableRecord', 'ksc.RestList',
  (EditableRecord, RestList) ->

    ->
      new RestList
        endpoint:
          url: '/api/archetype/'
        record
          class: EditableRecord
          contract:
            id:   {type: 'number'}
            name: {type: 'string'}
          idProperty: 'id'
          url: '/api/archetype/<id>'
]
