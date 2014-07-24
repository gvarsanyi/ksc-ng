
app.factory 'ksc.Record', [
  'ksc.RecordContract', 'ksc.Utils',
  (RecordContract, Utils) ->

    OPTIONS    = '_options'
    PARENT_KEY = '_parentKey'
    SAVED      = '_saved'

    define_value = Utils.defineValue
    has_own      = Utils.hasOwn
    is_object    = Utils.isObject


    class Record
      # virtual properties:
      # - _id:          object
      # - _options:     object
      # - _parent:      object
      # - _parentKey:   number|string
      # - _primaryId:   object
      # - _saved:       object

      constructor: (data={}, options={}, parent, parent_key) ->
        unless is_object data
          throw new Error 'First argument (data) must be null or object'

        unless is_object options
          throw new Error 'Second argument (options) must be null or object'

        record = @

        define_value record, OPTIONS, options

        if has_own options, 'contract'
          options.contract = new RecordContract options.contract

        if parent? or parent_key?
          unless is_object parent
            throw new Error 'Parent must be an object'
          define_value record, '_parent', parent

          if parent_key?
            unless typeof parent_key in ['string', 'number']
              throw new Error 'Parent key must be a string or a number'
            define_value record, PARENT_KEY, parent_key

        record._replace data

        Record.setId record

        # hide (set to non-enumerable) non-data properties/methods
        ref = record
        while is_object ref = Object.getPrototypeOf ref
          for own key of ref
            Object.defineProperty ref, key, enumerable: false

        RecordContract.finalizeRecord record


      _clone: (return_plain_object=false) ->
        clone = {}
        record = @
        for key, value of record
          if has_own record[SAVED], key
            value = record[SAVED][key]
          if is_object value
            value = value._clone true
          clone[key] = value
        if return_plain_object
          return clone

        return new record.constructor clone

      _entity: ->
        @_clone true

      _replace: (data) ->
        for key of data when key.substr(0, 1) is '_'
          throw new Error 'property names must not start with underscore ' + key

        record = @

        options = record[OPTIONS]

        contract = options.contract

        # check if data is changing with the replacement
        saved = record[SAVED]
        changed = true
        if not record._changes and saved
          changed = false

          for key, value of data when not Utils.identical saved[key], value
            changed = true
            break

          unless changed
            for key of saved when not has_own data, key
              if not contract or contract._default(key) isnt saved[key]
                changed = true
                break

        set_property = (key, value) ->
          if typeof value is 'function'
            throw new Error 'Property must not be a function'

          contract?._match key, value

          if is_object value
            if value instanceof Record
              value = value._clone 1

            class_ref = options.subtreeClass or Record

            subopts = {}
            if contract
              subopts.contract = contract[key].contract

            value = new class_ref value, subopts, record, key

          define_value saved, key, value, false, true

        if changed
          if saved and not contract
            for key of saved
              delete record[key]

          define_value record, SAVED, saved = {}

          for key, value of data
            set_property key, value

          if contract
            for own key, value of contract when not has_own saved, key
              set_property key, contract._default key

          Object.freeze saved

          for key, value of saved
            define_value record, key, value, false, true

        changed


      @setId: (record) ->
        # set IDs only for records in list (no stand-alones, no subrecords)
        return if record[PARENT_KEY]

        key = 'idProperty'
        options = record[OPTIONS]

        unless options[key] # assign first as ID
          for k of record[SAVED]
            options[key] = k
            break

        return unless (id_property = options[key])

        if Array.isArray id_property
          unless primary_id = record[id_property[0]]
            throw new Error 'First part of the idProperty must have a value'
          parts = (record[pt] for pt in id_property when record[pt]?)
          define_value record, '_id', parts.join '-'
          define_value record, '_primaryId', primary_id
        else
          define_value record, '_id', record[id_property]
]
