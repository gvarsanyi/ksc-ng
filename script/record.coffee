
app.factory 'ksc.Record', [
  'ksc.EventEmitter', 'ksc.RecordContract', 'ksc.errors', 'ksc.utils',
  (EventEmitter, RecordContract, errors, utils) ->

    EVENTS      = '_events'
    ID          = '_id'
    ID_PROPERTY = 'idProperty'
    OPTIONS     = '_options'
    PARENT      = '_parent'
    PARENT_KEY  = '_parentKey'
    PSEUDO      = '_pseudo'

    define_value = utils.defineValue
    has_own      = utils.hasOwn
    is_object    = utils.isObject

    object_required = (name, value, arg) ->
      unless is_object value
        inf = {}
        inf[name] = value
        inf.argument = arg
        inf.acceptable = 'object'
        throw new errors.ArgumentType inf

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

      # @property [object|null] reference to related event-emitter instance
      _events: undefined

      # @property [number|string] record id
      _id: undefined

      # @property [object] record-related options
      _options: undefined

      # @property [object] reference to parent record or list
      _parent: undefined

      # @property [number|string] key on parent record
      _parent_key: undefined

      # @property [number] record id
      _pseudo: undefined


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
          define_value record, PARENT, parent

          if parent_key?
            unless typeof parent_key in ['number', 'string']
              throw new errors.Type
                parent_key: parent_key
                argument:   4
                acceptable: ['number', 'string']
            define_value record, PARENT_KEY, parent_key
            delete record[ID]
            delete record[PSEUDO]

        # hide (set to non-enumerable) non-data properties/methods
        for key, refs of utils.getProperties Object.getPrototypeOf record
          for ref in refs
            Object.defineProperty ref, key, enumerable: false

        unless parent_key?
          define_value record, ID, undefined
          define_value record, PSEUDO, undefined
          define_value record, EVENTS, new EventEmitter
          record[EVENTS].halt()

        record._replace data

        if parent_key?
          define_value record, EVENTS, null
        else
          record[EVENTS].unhalt()

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

      @event 'update' sends out message on changes:
        events.emit {node: record, action: 'replace'}

      @return [boolean] indicates change in data
      ###
      _replace: (data, rec_cmp) ->
        record = @

        if record[EVENTS] is null and record[PARENT_KEY]
          throw new errors.Permission
            key:         record[PARENT_KEY]
            description: 'can not replace subobject'

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
            unless utils.identical record[key], value
              set_property key, value
        else
          for key, value of data
            if key.substr(0, 1) is '_'
              throw new errors.Key {key, description: 'can not start with "_"'}
            if typeof value is 'function'
              throw new errors.Type {value, notAcceptable: 'function'}
            unless utils.identical value, record[key]
              set_property key, value

          for key of record when not has_own data, key
            delete record[key]
            changed = true

        if changed and events = record[EVENTS]
          Record.emitUpdate record, 'replace'

        changed


      ###
      Event emission - with handling complexity around subobjects

      @param [object] record reference to record or subrecord object
      @param [string] action 'revert', 'replace', 'set', 'delete' etc
      @param [object] extra_info (optional) info to be attached to the emission

      @return [undefined]
      ###
      @emitUpdate: (record, action, extra_info={}) ->
        path   = []
        source = record

        until events = source[EVENTS]
          path.unshift source[PARENT_KEY]
          source = source[PARENT]

        info = {node: record}
        unless record is source
          info.parent = source
          info.path = path
        info.action = action

        for key, value of extra_info
          info[key] = value

        events.emit 'update', info

        old_id = source[ID]
        Record.setId source

        unless source[EVENTS]._halt
          source[PARENT]?._recordChange? source, info, old_id

        return


      ###
      Define _id for the record

      @param [Record] record record instance to be updated

      @return [undefined]
      ###
      @setId: (record) ->
        options = record[OPTIONS]

        unless options[ID_PROPERTY] # assign first as ID
          for k of record
            options[ID_PROPERTY] = k
            break

        define_value record, ID, record[options[ID_PROPERTY]]

        return
]
