
ksc.factory 'ksc.Record', [
  'ksc.ArrayTracker', 'ksc.EventEmitter', 'ksc.RecordContract', 'ksc.error',
  'ksc.util',
  (ArrayTracker, EventEmitter, RecordContract, error,
   util) ->

    _ARRAY       = '_array'
    _EVENTS      = '_events'
    _ID          = '_id'
    _OPTIONS     = '_options'
    _PARENT      = '_parent'
    _PARENT_KEY  = '_parentKey'
    _PRIMARY_KEY = '_primaryId'
    _PSEUDO      = '_pseudo'
    _SAVED       = '_saved'
    CONTRACT     = 'contract'

    define_get_set = util.defineGetSet
    define_value   = util.defineValue
    has_own        = util.hasOwn
    is_array       = Array.isArray
    is_key_conform = util.isKeyConform
    is_object      = util.isObject


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
    - .options.subtreeClass

    @author Greg Varsanyi
    ###
    class Record

      # @property [array] array container if data set is array type
      _array: undefined #DOC-ONLY#

      # @property [object|null] reference to related event-emitter instance
      _events: undefined #DOC-ONLY#

      # @property [number|string] record id
      _id: undefined #DOC-ONLY#

      # @property [number|string] getter/setter for id property
      _idProperty: undefined #DOC-ONLY#

      # @property [object] record-related options
      _options: undefined #DOC-ONLY#

      # @property [object] reference to parent record or list
      _parent: undefined #DOC-ONLY#

      # @property [number|string] key on parent record
      _parentKey: undefined #DOC-ONLY#

      # @property [number] record id
      _pseudo: undefined #DOC-ONLY#

      # @property [object] container of saved data
      _saved: undefined #DOC-ONLY#


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

        Record.objReq 'data',    data,    1
        Record.objReq 'options', options, 2

        record = @

        define_value record, _OPTIONS, options
        define_value record, _SAVED, {}

        if has_own options, CONTRACT
          contract = options[CONTRACT] = new RecordContract options[CONTRACT]

        define_value record, _PARENT, parent
        if parent? or parent_key?
          Record.objReq 'options', parent, 3

          if parent_key?
            is_key_conform parent_key, 1, 4
            define_value record, _PARENT_KEY, parent_key
            delete record[_ID]
            delete record[_PRIMARY_KEY]
            delete record[_PSEUDO]

        # hide (set to non-enumerable) non-data properties/methods
        for target in (if contract then [record, contract] else [record])
          for key, refs of util.propertyRefs Object.getPrototypeOf target
            for ref in refs
              Object.defineProperty ref, key, enumerable: false

        id_property = options.idProperty
        unless parent_key? # top level record (not subrecord)
          define_value record, _ID
          define_value record, _PRIMARY_KEY
          define_value record, _PSEUDO
          define_value record, _EVENTS, new EventEmitter

          # id property getter/setter
          Record.checkIdProperty id_property
          id_property_get = ->
            if id_property?
              return id_property
            record[_PARENT]?.idProperty
          id_property_set = (value) ->
            Record.checkIdProperty value
            Record.setId record
            return
          define_get_set record, '_idProperty', id_property_get, id_property_set
          define_get_set options, 'idProperty', id_property_get,
                         id_property_set, 1

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
      @param [boolean] exclude_static (optional) avoid cloning non-getters
        (statically assigned in runtime without using {Record#_setProperty)

      @return [Object|Record] the new instance with identical data
      ###
      _clone: (return_plain_object, exclude_static) ->
        record = @

        clone = {}
        if return_plain_object
          for key, value of record[_SAVED]
            if value?._clone
              value = value._clone 1, exclude_static
            clone[key] = value
        else
          statics = {}
          for key, value of record[_SAVED]
            if value?._clone
              unless exclude_static
                statics[key] = Record.getAllStatic value
              value = value._clone 0, 1, 1
            clone[key] = value
          clone = new (record.constructor) clone
          for key, value of statics
            for key2, value2 of value
              clone[key][key2] = value2

        unless exclude_static
          Record.getAllStatic record, clone

        clone


      ###
      Placeholder method, throws error on read-only Record. See
      {EditableRecord#_delete} for read/write implementation.

      @throw [PermissionError] Tried to delete on a read-only record

      @return [boolean] Never happens, always throws error
      ###
      _delete: ->
        error.Permission {keys, description: 'Read-only Record'}

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
      Getter function that reads a property of the object. Gets the saved state
      from {Record#._saved} (there is no other state for a read-only Record).

      If value is an array, it will return a native Array with the values
      instead of the Record instance. Original Record object is available on the
      array's ._record property. See {Record.arrayFilter}.

      @param [number|string] key Property name

      @throw [ArgumentTypeError] Key is missing or is not key conform (string or
        number)

      @return [mixed] value for key
      ###
      _getProperty: (key) ->
        is_key_conform key, 1, 1
        Record.arrayFilter @[_SAVED][key]

      ###
      (Re)define the initial data set

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
        events = record[_EVENTS]

        # _replace() is not allowed on subnodes, only for the first run
        # here it checks against record._events, possible values are:
        #  - object: top-level node
        #  - undefined: subnode, but this is init time
        #  - null: subnode, but this is post init time (should throw an error)
        if events is null
          error.Permission
            key:         record[_PARENT_KEY]
            description: 'can not replace subobject'

        replacing = true

        if is_array data
          flat = (value for value in data)

          Record.arrayify record
          changed = 1
          arr = record[_ARRAY]

          # setter should be init-sensitive unless it's toggled by
          # EditableRecord in run-time
          arr._tracker.set = (index, value) ->
            record._setProperty index, value, replacing

          if flat.length and arr.push.apply arr, flat
            changed = 1
        else
          Record.dearrayify record

          flat = {}
          for key, value of data
            flat[key] = value

          if contract = record[_OPTIONS][CONTRACT]
            for key, value of contract when not has_own flat, key
              flat[key] = contract._default key

          for key, value of flat
            Record.getterify record, key
            if record._setProperty key, value, replacing
              changed = 1

        for key of record[_SAVED] when not has_own flat, key
          delete record[key]
          delete record[_SAVED][key]
          changed = 1

        if changed and events and emit_event
          Record.emitUpdate record, 'replace'

        replacing = false
        !!changed

      ###
      Setter function that writes a property of the object.
      On initialization time (e.g. when called from {Record#_replace} it saves
      values to {Record#._saved} or throws error later when trying to (re)write
      a property on read-only Record.

      If there is a contract for the record it will use {Record.valueCheck} to
      match against it.
      Also will not allow function values nor property names starting with '_'.

      @param [number|string] key Property name
      @param [mixed] value Data to store
      @param [boolean] initial Indicates initiation time (optional)

      @throw [ArgumentTypeError] Key is missing or is not key conform (string or
        number)
      @throw [ContractBreakError] Value does not match contract for key
      @throw [ValueError] When trying to pass a function as value

      @return [boolean] indication of value change
      ###
      _setProperty: (key, value, initial) ->
        record = @
        saved  = record[_SAVED]

        unless initial
          error.Permission {key, value, description: 'Read-only Record'}

        Record.valueCheck record, key, value

        if has_own(saved, key) and util.identical value, record[key]
          return false

        define_value saved, key, Record.valueWrap(record, key, value), 0, 1
        Record.getterify record, key

        true

      ###
      Helper function that filters values that reference arrayified Records.
      All other values are returned as is.

      From array-records the native Array object will be returned. Also this
      method makes sure that all the Record properties are copied over to
      the native returned Array. I.e. {Record#_clone()} and other methods will
      be also available on the returned array.

      @param [Record] record reference to record/subrecord object or value

      @return [mixed]
      ###
      @arrayFilter: (record) ->
        unless arr = record?[_ARRAY]
          return record

        object = record
        marked = {}
        while object and object.constructor isnt Object
          for key in Object.getOwnPropertyNames object
            if key isnt _ARRAY and key.substr(0, 1) is '_' and
            not has_own marked, key
              marked[key] = Object.getOwnPropertyDescriptor object, key
          object = Object.getPrototypeOf object
        for key of arr
          if key isnt '_record' and key.substr(0, 1) is '_' and
          not has_own marked, key
            delete arr[key]
        for key, desc of marked
          Object.defineProperty arr, key, desc
        define_value arr, '_record', record

        arr

      ###
      Helper function that turns a Record instance into an array container.
      It utilizes {ArrayTracker} and stores it as {Record#_array}.

      @param [Record] record Reference to Record object

      @return [ArrayTracker] array tracker instance
      ###
      @arrayify: (record) ->
        define_value record, _ARRAY, arr = []
        new ArrayTracker arr,
          store: record[_SAVED]
          get: (index) ->
            record._getProperty index
          set: (index, value) ->
            record._setProperty index, value
          del: (index) ->
            record._delete index
            false

      ###
      Helper function that matches value against idProperty requirement.
      Namely, idProperty must be either
       - a non-empty string, or
       - a number, or
       - a non-empty array of non-empty strings and/or numbers

      @param [mixed] id_property idProperty value

      @return [undefined]
      ###
      @checkIdProperty: (id_property) ->
        err = ->
          error.Value
            item:        item
            description: 'idProperty items must be key conform'

        if id_property?
          if is_array id_property
            check = id_property
          else
            check = [id_property]
          unless check.length
            err()
          for item in check when not is_key_conform item
            err()
        return


      ###
      Helper function that removes the {Record#_array} property effectively
      changing the Record instance's behavior into that of a regular object's.

      @param [Record] record Reference to Record object

      @return [boolean] indicates if {Record#_array} deletion was successful
      ###
      @dearrayify: (record) ->
        delete record[_ARRAY]

      ###
      Event emission - with handling complexity around subobjects

      @param [Record] record Reference to record or subrecord object
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
          source[_PARENT]?._recordChange source, info, old_id

        events.emit 'update', info
        return

      ###
      Helper method that gets all static properties (not getter/setter
      properties, e.g. the ones that were NOT assigned by {Record#_setProperty})

      Uses the provided object as clone target or creates a new one.

      @param [Record] record Reference to record object
      @param [object] target (optional) Reference to property copy target

      @return [object] copied static properties
      ###
      @getAllStatic: (record, target={}) ->
        for key, value of record
          if has_own Object.getOwnPropertyDescriptor(record, key), 'value'
            target[key] = value
        target

      ###
      Helper function that creates a new getter/setter property (if property
      does not exist yet).
      The getter and setter will target methods {Record#_getProperty} and
      {Record#_setProperty} respectively.

      @param [Record] record Reference to record or subrecord object
      @param [number|string] index

      @return [undefined]
      ###
      @getterify: (record, index) ->
        unless has_own record, index
          define_get_set record, index, (-> record._getProperty index),
                         ((value) -> record._setProperty index, value), 1
        return

      ###
      Helper function that throws an ArgumentTypeError if requirements are
      not met (argument is not an object)

      @param [string] name Argument key
      @param [mixed] value Argument value
      @param [number] arg Argument index

      @throw [ArgumentTypeError] Argument is not an object

      @return [undefined]
      ###
      @objReq: (name, value, arg) ->
        unless is_object value
          inf = {}
          inf[name] = value
          inf.argument = arg
          inf.required = 'object'
          error.ArgumentType inf
        return

      ###
      Define _id for the record

      Composite IDs will be used and ._primaryId will be created if
      idProperty is an Array. The composite is c
      - Parts are stringified and joined by '-'
      - If a part is empty (e.g. '' or null), the part will be skipped in ._id
      - If primary part of composite ID is null, the whole ._id is going to
        be null (becomes a pseudo/new record)
      @example
        list = new List {record: {idProperty: ['id', 'otherId', 'name']}}
        record = new EditableRecord {id: 1, otherId: 2, name: 'x'}
        list.push record
        console.log record._id, record._primaryId # '1-2-x', 1

        record.otherId = null
        console.log record._id, record._primaryId # '1-x', 1

        record.id = null
        console.log record._id, record._primaryId # null, null

      @param [Record] record Record instance to be updated

      @return [undefined]
      ###
      @setId: (record) ->
        id_property_check = (key) ->
          if contract = record[_OPTIONS][CONTRACT]
            unless contract[key]?
              error.ContractBreak {key, contract, mismatch: 'idProperty'}
            unless contract[key].type in ['string', 'number']
              error.ContractBreak {key, contract, required: 'string or number'}
            unless record[key]?
              error.ContractBreak
                key:      key
                value:    record[key]
                mismatch: 'idProperty value must exist (not nullable)'
          return

        if (id_property = record._idProperty)?
          if is_array id_property
            composite = []
            for part, i in id_property
              id_property_check part
              if is_key_conform value = record[part]
                composite.push value
              else unless i # if first part is unset, fall back to null
                break

            primary = record[id_property[0]]
            id = if composite.length then composite.join '-' else primary
            define_value record, _ID, id
            define_value record, _PRIMARY_KEY, primary
          else
            id_property_check id_property
            define_value record, _ID, record[id_property]
        else
          define_value record, _ID
          define_value record, _PRIMARY_KEY

        return

      ###
      Helper function that check value and key criteries (like contract match).
      Used by {Record#_setProperty}

      @param [Record] record Reference to Record instance
      @param [number|string] key Record property ID
      @param [mixed] value

      @throw [ArgumentTypeError] Key is missing or is not key conform (string or
        number)
      @throw [ContractBreakError] Value does not match contract for key
      @throw [ValueError] Function was passed as value

      @return [undefined]
      ###
      @valueCheck: (record, key, value) ->
        is_key_conform key, 1, 1
        if contract = record[_OPTIONS][CONTRACT]
          contract._match (if record[_ARRAY] then 'all' else key), value
        else
          if typeof key is 'string' and key.substr(0, 1) is '_'
            error.ArgumentType
              key:         key
              argument:    1
              description: 'can not start with "_"'
          if typeof value is 'function'
            error.Value {value, description: 'can not be function'}
        return

      ###
      Helper function that creates a new Record for sub-objects or sub-arrays
      and returns them (or the static value as is)
      Used by {Record#_setProperty}

      Will use ._options.subtreeClass as subrecord class if defined (or falls
      ack to Record). This is supposed to be used only by {EditableRecord} so
      that the children would also be editable, but not of the constructor
      class (i.e. not carrying any overrides).

      @param [Record] record Reference to Record instance
      @param [number|string] key Record property ID
      @param [mixed] value

      @return [mixed] value or reference to the wrapped Record object
      ###
      @valueWrap: (record, key, value) ->
        contract = record[_OPTIONS][CONTRACT]

        if is_object value
          if value._clone # instanceof Record or processed Array
            value = value._clone 1

          class_ref = record[_OPTIONS].subtreeClass or Record

          if contract
            if key_contract = contract[key]
              if key_contract.array
                subopts = contract: all: key_contract.array
              else
                subopts = contract: key_contract[CONTRACT]
            else # if record[_ARRAY] and contract.all
              subopts = contract: contract.all.contract
          value = new class_ref value, subopts, record, key

        value
]
