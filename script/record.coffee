
ksc.factory 'ksc.Record', [
  'ksc.ArrayTracker', 'ksc.EventEmitter', 'ksc.RecordContract', 'ksc.error',
  'ksc.util',
  (ArrayTracker, EventEmitter, RecordContract, error,
   util) ->

    _ARRAY      = '_array'
    _EVENTS     = '_events'
    _ID         = '_id'
    _OPTIONS    = '_options'
    _PARENT     = '_parent'
    _PARENT_KEY = '_parentKey'
    _PSEUDO     = '_pseudo'
    _SAVED      = '_saved'
    ARRAY       = 'array'
    CONTRACT    = 'contract'
    ID_PROPERTY = 'idProperty'

    define_value = util.defineValue
    has_own      = util.hasOwn
    is_array     = Array.isArray
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

      # @property [array] array container if data set is array type
      _array: undefined

      # @property [object|null] reference to related event-emitter instance
      _events: undefined

      # @property [number|string] record id
      _id: undefined

      # @property [object] record-related options
      _options: undefined

      # @property [object] reference to parent record or list
      _parent: undefined

      # @property [number|string] key on parent record
      _parentKey: undefined

      # @property [number] record id
      _pseudo: undefined

      # @property [object] container of saved data
      _saved: undefined


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
        unless is_object data
          error.Type {data, required: 'object'}

        object_required 'data',    data,    1
        object_required 'options', options, 2

        record = @

        define_value record, _OPTIONS, options
        define_value record, _SAVED, {}

        if has_own options, CONTRACT
          contract = options[CONTRACT] = new RecordContract options[CONTRACT]

        if parent? or parent_key?
          object_required 'options', parent, 3
          define_value record, _PARENT, parent

          if parent_key?
            unless util.isKeyConform parent_key
              error.Type
                parent_key: parent_key
                argument:   4
                required:   'key conform value'
            define_value record, _PARENT_KEY, parent_key
            delete record[_ID]
            delete record[_PSEUDO]

        # hide (set to non-enumerable) non-data properties/methods
        for target in (if contract then [record, contract] else [record])
          for key, refs of util.propertyRefs Object.getPrototypeOf target
            for ref in refs
              Object.defineProperty ref, key, enumerable: false

        unless parent_key?
          define_value record, _ID, undefined
          define_value record, _PSEUDO, undefined
          define_value record, _EVENTS, new EventEmitter
          record[_EVENTS].halt()

        record._replace data

        if parent_key?
          define_value record, _EVENTS, null
        else
          record[_EVENTS].unhalt()

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
            value = value._clone 1
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
        @_clone 1

      ###
      (Re)define the initial data set

      @note Will try and create an ._options.idProperty if it is missing off of
        the first key in the dictionary, so that it can be used as ._id
      @note Will set ._options.idProperty value of the data set to null if it is
        not defined

      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore

      @param [object] data Key-value map of data

      @event 'update' sends out message on changes:
        events.emit {node: record, action: 'replace'}

      @return [boolean] indicates change in data
      ###
      @initIdProperty: (record, data) ->
        options  = record[_OPTIONS]
        contract = options[CONTRACT]

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

        if record[_EVENTS] # a top-level node of record (create _id on top only)
          if id_property = options[ID_PROPERTY]
            if id_property instanceof Array
              for part in id_property
                id_property_contract_check part
                data[part] ?= null
            else
              id_property_contract_check id_property
              data[id_property] ?= null


      _valueCheck: (key, value) ->
        if contract = @[_OPTIONS][CONTRACT]
          contract._match (if @[_ARRAY] then 'all' else key), value
        else
          if key.substr(0, 1) is '_'
            error.Key {key, description: 'can not start with "_"'}
          if typeof value is 'function'
            error.Type {value, description: 'can not be function'}

      @valueWrap: (record, key, value) ->
        contract = record[_OPTIONS][CONTRACT]

        if is_object value
          if value instanceof Record
            value = value._clone 1

          class_ref = record[_OPTIONS].subtreeClass or Record

          if key_contract = contract?[key]
            if opt = key_contract[ARRAY]
              subopts = contract: all: opt
            if opt = key_contract[CONTRACT]
              subopts = contract: opt
          value = new class_ref value, subopts, record, key

        value

      _getProperty: (key) ->
        value = @[_SAVED][key]
        value?[_ARRAY] or value

      _setProperty: (key, value, initial) ->
        record = @
        saved  = record[_SAVED]

        unless initial
          error.Permission {key, value, description: 'Read-only Record'}

        record._valueCheck key, value

        if has_own(saved, key) and util.identical value, record[key]
          return false

        define_value saved, key, Record.valueWrap(record, key, value), 0, 1

        true

      _replace: (data) ->
        record = @

        # _replace() is not allowed on subnodes, only for the first run
        # here it checks against record._events, possible values are:
        #  - object: top-level node
        #  - undefined: subnode, but this is init time
        #  - null: subnode, but this is post init time (should throw an error)
        if record[_EVENTS] is null
          error.Permission
            key:         record[_PARENT_KEY]
            description: 'can not replace subobject'

        Record.initIdProperty record, data

        if is_array data
#           unless arr = record[_ARRAY]
#             define_value record, _ARRAY, arr = []
#             new ArrayTracker arr, record[_SAVED]
#           else
#             util.empty arr
#           arr.push data...
        else
#           delete record[_ARRAY]

          flat = {}
          for key, value of data
            flat[key] = value

          if contract = record[_OPTIONS][CONTRACT]
            for key, value of contract when not has_own flat, key
              flat[key] = contract._default key

          for key, value of flat
            do (key) ->
              util.defineGetSet record, key, (-> record._getProperty key),
                                ((value) -> record._setProperty key, value), 1
            if record._setProperty key, value, 1
              changed = true

          for key of record[_SAVED] when not has_own flat, key
            delete record[key]
            delete record[_SAVED][key]

        if changed and record[_EVENTS]
          Record.emitUpdate record, 'replace'

        changed or false


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

        until events = source[_EVENTS]
          path.unshift source[_PARENT_KEY]
          source = source[_PARENT]

        info = {node: record}
        unless record is source
          info.parent = source
          info.path = path
        info.action = action

        for key, value of extra_info
          info[key] = value

        old_id = source[_ID]
        Record.setId source

        unless source[_EVENTS]._halt
          source[_PARENT]?._recordChange? source, info, old_id

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
        if id_property = record[_OPTIONS][ID_PROPERTY]
          if id_property instanceof Array
            composite = []
            for part, i in id_property
              if util.isKeyConform record[part]
                composite.push record[part]
              else unless i # if first part is unset, fall back to null
                break
            id = if composite.length then composite.join('-') else null
            define_value record, _ID, id
            define_value record, '_primaryId', record[id_property[0]]
          else
            value = record[id_property]
            define_value record, _ID, if value? then value else null

        return
]
