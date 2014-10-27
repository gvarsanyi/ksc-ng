
module_name.factory 'namespace.endpointArchetypeFactory', [
  'ksc.RestList',
  (RestList) ->

    ->
      new RestList
        endpoint:
          url: '/api/my-endpoint/'
        record
          # class: EditableRecord # ksc.EditableRecord is the default Record class
          contract:
            id:   {type: 'number'}
            name: {type: 'string'}
          idProperty: 'id'
          url: '/api/my-endpoint/<id>'
]
