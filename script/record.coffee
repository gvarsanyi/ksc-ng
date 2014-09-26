
app.factory 'ksc.Record', [
  'ksc.EventEmitter', 'ksc.RecordContract', 'ksc.error', 'ksc.util',
  (EventEmitter, RecordContract, error, util) ->

    EVENTS      = '_events'
    ID          = '_id'
    ID_PROPERTY = 'idProperty'
    OPTIONS     = '_options'
    PARENT      = '_parent'
    PARENT_KEY  = '_parentKey'
    PSEUDO      = '_pseudo'

    define_value = util.defineValue
    has_own      = util.hasOwn
    is_object    = util.isObject

    object_required = (name, value, arg) ->
      unless is_object value
        inf = {}
        inf[name] = value
        inf.argument = arg
        inf.required = 'object'
        error.ArgumentType inf

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
        object_required 'data',    data,    1
        object_required 'options', options, 2

        record = @

        define_value record, OPTIONS, options

        if has_own options, 'contract'
          options.contract = new RecordContract options.contract

        if parent? or parent_key?
          object_required 'options', parent, 3
          define_value record, PARENT, parent

          if parent_key?
            unless util.isKeyConform parent_key
              error.Type
                parent_key: parent_key
                argument:   4
                required:   'key conform value'
            define_value record, PARENT_KEY, parent_key
            delete record[ID]
            delete record[PSEUDO]

        # hide (set to non-enumerable) non-data properties/methods
        for key, refs of util.propertyRefs Object.getPrototypeOf record
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

      @note Will try and create an ._options.idProperty if it is missing off of
        the first key in the dictionary, so that it can be used as ._id
      @note Will set ._options.idProperty value of the data set to null if it is
        not defined

      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore

      @param [object] data Key-value map of data
      @param [boolean] emit_event if replace should trigger event emission
        (defaults to true)

      @event 'update' sends out message on changes:
        events.emit {node: record, action: 'replace'}

      @return [boolean] indicates change in data
      ###
      _replace: (data, emit_event=true) ->
        record = @

        # _replace() is not allowed on subnodes, only for the first run
        # here it checks against record._events, possible values are:
        #  - object: top-level node
        #  - undefined: subnode, but this is init time
        #  - null: subnode, but this is post init time (should throw an error)
        if record[EVENTS] is null
          error.Permission
            key:         record[PARENT_KEY]
            description: 'can not replace subobject'

        options = record[OPTIONS]

        contract = options.contract

        unless options[ID_PROPERTY]? # assign first as ID
          for key of data
            options[ID_PROPERTY] = key
            break

        id_property_contract_check = (key) ->
          if contract
            unless contract[key]?
              error.ContractBreak {key, contract, mismatch: 'idProperty'}
            unless contract[key].type in ['string', 'number']
              error.ContractBreak {key, contract, required: 'string or number'}

        if record[EVENTS] # a top-level node of record (create _id on top only)
          if id_property = options[ID_PROPERTY]
            if id_property instanceof Array
              for part in id_property
                id_property_contract_check part
                data[part] ?= null
            else
              id_property_contract_check id_property
              data[id_property] ?= null

        changed = false

        set_property = (key, value) ->
          if util.identical record[key], value
            return

          if is_object value
            if value instanceof Record
              value = value._clone 1

            class_ref = options.subtreeClass or Record

            subopts = {}
            if contract
              subopts.contract = contract[key].contract

            value = new class_ref value, subopts, record, key

          changed = true
          define_value record, key, value, 0, 1

        # check if data is changing with the replacement
        if contract
          for key, value of data
            contract._match key, value

          for key of contract
            value = if has_own(data, key)
              data[key]
            else
              contract._default key
            set_property key, value
        else
          for key, value of data
            if key.substr(0, 1) is '_'
              error.Key {key, description: 'can not start with "_"'}
            if typeof value is 'function'
              error.Type {value, description: 'can not be function'}
            set_property key, value

          for key of record when not has_own data, key
            delete record[key]
            changed = true

        if changed and record[EVENTS] and emit_event
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

        old_id = source[ID]
        Record.setId source

        unless source[EVENTS]._halt
          source[PARENT]?._recordChange? source, info, old_id

        events.emit 'update', info

        return

      ###
      Define _id for the record

      Composite IDs will be used and ._primaryId will be created if
      .options.idProperty is an Array. The composite is c
      - Parts are stringified and joined by '-'
      - If a part is empty (e.g. '' or null), the part will be skipped in ._id
      - If primary part of composite ID is null, the whole ._id is going to
        be null (becomes a pseudo/new record)
      @example
        record = new EditableRecord {id: 1, otherId: 2, name: 'x'},
                                    {idProperty: ['id', 'otherId', 'name']}
        console.log record._id, record._primaryId # '1-2-x', 1

        record.otherId = null
        console.log record._id, record._primaryId # '1-x', 1

        record.id = null
        console.log record._id, record._primaryId # null, null

      @param [Record] record record instance to be updated

      @return [undefined]
      ###
      @setId: (record) ->
        if id_property = record[OPTIONS][ID_PROPERTY]
          if id_property instanceof Array
            composite = []
            for part, i in id_property
              if util.isKeyConform record[part]
                composite.push record[part]
              else unless i # if first part is unset, fall back to null
                break
            id = if composite.length then composite.join('-') else null
            define_value record, ID, id
            define_value record, '_primaryId', record[id_property[0]]
          else
            value = record[id_property]
            define_value record, ID, if value? then value else null

        return
]
