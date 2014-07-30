
app.factory 'ksc.Record', [
  'ksc.Errors', 'ksc.RecordContract', 'ksc.Utils',
  (Errors, RecordContract, Utils) ->

    OPTIONS    = '_options'
    PARENT_KEY = '_parentKey'

    define_value = Utils.defineValue
    has_own      = Utils.hasOwn
    is_object    = Utils.isObject

    undef = {}.undef # guaranteed undefined

    object_required = (name, value, arg) ->
      unless is_object value
        inf = {}
        inf[name] = value
        inf.argument = arg
        inf.acceptable = 'object'
        throw new Errors.ArgumentType inf

    ###
    Read-only key-value style record with supporting methods and optional
    multi-level hieararchy.

    Supporting methods and properties start with '_' and are not enumerable
    (e.g. hidden when doing `for k of record`, but will match
    record.hasOwnProperty('special_key_name') )

    Also supports contracts (see: {RecordContract})

    @example
        record = new Record {a: 1, b: 1}
        console.log record.a # 1
        try
          record.a = 2 # try overriding
        console.log record.a # 1

    Options that may be used
    - .options.contract
    - .options.idProperty
    - .options.subtreeClass

    @author Greg Varsanyi
    ###
    class Record

      # @property [number|string] record id
      _id: undef

      # @property [object] record-related options
      _options: null

      # @property [object] reference to parent record or list
      _parent: undef

      # @property [number|string] key on parent record
      _parent_key: undef


      ###
      Create the Record instance with initial data and options

      @throw [ArgumentTypeError] data, options, parent, parent_key type mismatch

      Possible errors thrown at {Record#_replace}
      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore

      @param [object] data (optional) data set for the record
      @param [object] options (optional) options to define endpoint, contract,
        id key property etc
      @param [object] parent (optional) reference to parent (list or
        parent record)
      @param [number|string] parent_key (optional) parent record's key
      ###
      constructor: (data={}, options={}, parent, parent_key) ->
        object_required 'data', data, 1
        object_required 'options', options, 2

        record = @

        define_value record, OPTIONS, options

        if has_own options, 'contract'
          options.contract = new RecordContract options.contract

        if parent? or parent_key?
          object_required 'options', parent, 3
          define_value record, '_parent', parent

          if parent_key?
            unless typeof parent_key in ['number', 'string']
              throw new Errors.Type parent_key: parent_key
                                    argument:   4
                                    acceptable: ['number', 'string']
            define_value record, PARENT_KEY, parent_key

        # hide (set to non-enumerable) non-data properties/methods
        for key, refs of Utils.getProperties Object.getPrototypeOf record
          for ref in refs
            Object.defineProperty ref, key, enumerable: false

        record._replace data

        Record.setId record

        RecordContract.finalizeRecord record

      ###
      Clone record or contents

      @param [boolean] return_plain_object (optional) return a vanilla js Object

      @return [Object|Record] the new instance with identical data
      ###
      _clone: (return_plain_object=false) ->
        clone = {}
        record = @
        for key, value of record
          if is_object value
            value = value._clone true
          clone[key] = value
        if return_plain_object
          return clone

        new record.constructor clone

      ###
      Get the entity of the object, e.g. a vanilla Object with the data set
      This method should be overridden by any extending classes that have their
      own idea about the entity (e.g. it does not match the data set)
      This may be the most useful if you can not have a contract.

      Defaults to cloning to a vanilla Object instance.

      @return [Object] the new Object instance with the copied data
      ###
      _entity: ->
        @_clone true

      ###
      (Re)define the initial data set

      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore

      @param [object] data Key-value map of data

      @return [boolean] indicates change in data
      ###
      _replace: (data) ->
        record = @

        options = record[OPTIONS]

        contract = options.contract

        changed = false

        set_property = (key, value) ->
          if is_object value
            if value instanceof Record
              value = value._clone 1

            class_ref = options.subtreeClass or Record

            subopts = {}
            if contract
              subopts.contract = contract[key].contract

            value = new class_ref value, subopts, record, key

          changed = true
          define_value record, key, value, false, true

        # check if data is changing with the replacement
        if contract
          for key, value of data
            contract._match key, value

          for key of contract
            value = if has_own(data, key)
              data[key]
            else
              contract._default key
            unless Utils.identical record[key], value
              set_property key, value
        else
          for key, value of data
            if key.substr(0, 1) is '_'
              throw new Errors.Key {key, description: 'can not start with "_"'}
            if typeof value is 'function'
              throw new Errors.Type {value, notAcceptable: 'function'}
            unless Utils.identical value, record[key]
              set_property key, value

          for key of record when not has_own data, key
            delete record[key]
            changed = true

        changed


      ###
      Define _id for the record

      @param [Record] record record instance to be updated

      @return [undefined]
      ###
      @setId: (record) ->
        # set IDs only for records in list (no stand-alones, no subrecords)
        return if record[PARENT_KEY]

        key = 'idProperty'
        options = record[OPTIONS]

        unless options[key] # assign first as ID
          for k of record
            options[key] = k
            break

        return unless (id_property = options[key])

        define_value record, '_id', record[id_property]

        return
]
