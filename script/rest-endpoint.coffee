
app.factory 'ksc.RestEndpoint', [
  'ksc.RestList', 'ksc.RestRecord',
  (RestList, RestRecord) ->

#     options:
#       list:
#         bulkSave:      true
#         bulkDelete:    true
#         class:         RestList
#         responseArray: 'results'
#         url:           'api/Appointment'
#
#       record:
#         class:      EditableRecord
#         idProperty: ['appointmentId', 'occuranceId']
#         url:        'api/Appointment/<id>'

    class RestEndpoint
      constructor: (options) ->
        unless options?.record
          throw new Error 'endpoint record spec missing'

        if options.list
          class_ref = options.list.class or RestList
          return new class_ref options

        class_ref = options.record.class or RestRecord
        record = new class_ref
        record._base._options = options.record
        return record
]
