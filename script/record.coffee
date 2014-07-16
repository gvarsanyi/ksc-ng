
app.factory 'ksc.Record', [
  'ksc.Utils',
  (Utils) ->

    define_value = Utils.defineValue
    is_object    = Utils.isObject

    class Record
      @getId: (record) ->
        key = 'idProperty'
        options = record._options

        unless options[key] # assign first as ID
          for own key of record._saved
            options[key] = key
            break

        unless (id_property = options[key])
          throw new Error 'Could not identify ._options.idProperty'

        if Array.isArray id_property
          return (record[pt] for pt in id_property when record[pt]?).join '-'

        record[id_property]


      constructor: (data, options={}) ->
        @_replace data

        define_value @, '_options', options
        unless options.sub
          define_value @, '_id', Record.getId @, data

      _clone: (return_plain_object=false) ->
        clone = angular.copy @_saved

        unless return_plain_object
          return new @constructor clone

        clone

      _entity: ->
        @_clone true

      _replace: (data, class_ref=Record) ->
        for key of data when key.substr(0, 1) is '_'
          throw new Error 'property names must not start with underscore "_"'

        if @_saved
          for key of @_saved
            delete @[key]

        define_value @, '_saved', {}
        for key, value of data when typeof value isnt 'function'
          if is_object(value) and not (value instanceof Record)
            value = new class_ref value, sub: {parent: @, key}
          define_value @_saved, key, value, 1, 1

        for key, value of @_saved
          define_value @, key, value, 1, 1
]
