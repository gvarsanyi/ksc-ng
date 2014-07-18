
app.factory 'ksc.Record', [
  'ksc.Utils',
  (Utils) ->

    define_value  = Utils.defineValue
    has_own       = Utils.hasOwn
    is_enumerable = Utils.isEnumerable
    is_object     = Utils.isObject

    class Record
      @setId: (record) ->
        return if record._parentKey

        key = 'idProperty'
        options = record._options

        unless options[key] # assign first as ID
          for k of record._saved
            options[key] = k
            break

        unless (id_property = options[key])
          throw new Error 'Could not identify ._options.idProperty'

        if Array.isArray id_property
          unless primary_id = record[id_property[0]]
            throw new Error 'First part of the idProperty must have a value'
          parts = (record[pt] for pt in id_property when record[pt]?)
          define_value record, '_id', parts.join '-'
          define_value record, '_primaryId', primary_id
        else
          define_value record, '_id', record[id_property]

      # virtual properties:
      # - _id:        number|string
      # - _options:   {}
      # - _parent:    Record|List
      # - _parentKey: number|string

      constructor: (data, options={}, parent, parent_key) ->
        unless is_object data
          throw new Error 'First argument (data) must be null or object'

        unless is_object options
          throw new Error 'Second argument (options) must be null or object'

        define_value @, '_options', options

        if parent? or parent_key?
          unless is_object parent
            throw new Error 'Parent must be an object'
          define_value @, '_parent', parent

          if parent_key?
            unless typeof parent_key in ['string', 'number']
              throw new Error 'Parent key must be a string or a number'
            define_value @, '_parentKey', parent_key

        @_replace data

        Record.setId @

      _clone: (return_plain_object=false) ->
        clone = {}
        for key, value of @ when is_enumerable @, key
          if has_own @_saved, key
            value = @_saved[key]
          if is_object value
            value = value._clone true
          clone[key] = value
        if return_plain_object
          return clone

        return new @constructor clone

      _entity: ->
        @_clone true

      _replace: (data) ->
        for key of data when key.substr(0, 1) is '_'
          throw new Error 'property names must not start with underscore "_"'

        if @_saved
          for key of @_saved
            delete @[key]

        define_value @, '_saved', {}
        for key, value of data
          if typeof value is 'function'
            throw new Error 'Property must not be a function'
          if is_object value
            if value instanceof Record
              value = value._clone 1
            class_ref = @_options.subtreeClass or Record
            value = new class_ref value, null, @, key
          define_value @_saved, key, value, 1, 1

        for key, value of @_saved
          define_value @, key, value, 1, 1
]
