
ksc.factory 'ksc.EditableRecord', [
  'ksc.Record', 'ksc.error', 'ksc.util',
  (Record, error, util) ->

    _ARRAY        = '_array'
    _CHANGES      = '_changes'
    _CHANGED_KEYS = '_changedKeys'
    _DELETED_KEYS = '_deletedKeys'
    _EDITED       = '_edited'
    _EVENTS       = '_events'
    _OPTIONS      = '_options'
    _PARENT       = '_parent'
    _PARENT_KEY   = '_parentKey'
    _SAVED        = '_saved'

    define_value  = util.defineValue
    has_own       = util.hasOwn
    is_array      = Array.isArray
    is_enumerable = util.isEnumerable
    is_object     = util.isObject


    ###
    Stateful record (overrides and extensions for {Record})

    Also supports contracts (see: {RecordContract})

    @example
        record = new EditableRecord {a: 1, b: 1}
        record.a = 2
        console.log record._changes # 1
        console.log record._changedKeys # {a: true}
        record._revert()
        console.log record.a # 1
        console.log record._changes # 0

    Options that may be used
    - .options.contract
    - .options.subtreeClass

    @author Greg Varsanyi
    ###
    class EditableRecord extends Record

      # @property [object] dictionary of changed keys
      _changedKeys: undefined #DOC-ONLY#

      # @property [number] number of editions in the data set
      _changes: 0

      # @property [object] dictionary of deleted keys
      _deletedKeys: undefined #DOC-ONLY#

      # @property [object] dictionary of edited keys and new values
      _edited: undefined #DOC-ONLY#

      ###
      Create the EditableRecord instance with initial data and options

      @throw [ArgumentTypeError] data, options, parent, parent_key type mismatch

      Possible errors thrown at {Record#_replace}
      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore

      @param [object] data (optional) initital (saved) data set for the record
      @param [object] options (optional) options to define endpoint, contract,
        id key property etc
      @param [object] parent (optional) reference to parent (list or
        parent record)
      @param [number|string] parent_key (optional) parent record's key
      ###
      constructor: (data={}, options={}, parent, parent_key) ->
        unless is_object options
          error.ArgumentType {options, argument: 2, required: 'object'}
        options.subtreeClass = EditableRecord

        record = @

        define_value record, _EDITED, {}
        define_value record, _CHANGES, 0
        define_value record, _CHANGED_KEYS, {}
        define_value record, _DELETED_KEYS, {}
        define_value record, _SAVED, {}

        super data, options, parent, parent_key

      ###
      Clone record or contents

      @param [boolean] return_plain_object (optional) return a vanilla js Object
      @param [boolean] exclude_static (optional) avoid cloning non-getters
        (statically assigned in runtime without using
        {EditableRecord#_setProperty)
      @param [boolean] saved_only (optional) return only saved-state data

      @return [Object|EditableRecord] the new instance with identical data
      ###
      _clone: (return_plain_object, exclude_static, saved_only) ->
        record = @

        clone = super return_plain_object, exclude_static

        unless saved_only
          for key, value of record[_EDITED]
            if value?._clone
              value = value._clone return_plain_object, exclude_static
            if return_plain_object
              clone[key] = value
            else
              clone._setProperty key, value

          for key of record[_DELETED_KEYS]
            if return_plain_object
              delete clone[key]
            else
              clone._delete key

        unless return_plain_object or exclude_static
          Record.getAllStatic record, clone

        clone

      ###
      Mark property as deleted, remove it from the object, but keep the original
      data (saved status) for the property.

      @param [string|number] keys... One or more keys to delete

      @throw [ArgumentTypeError] Provided key is not string or number
      @throw [ContractBreakError] Tried to delete on a contracted record
      @throw [MissingArgumentError] No key was provided

      @event 'update' sends out message on changes:
        events.emit 'update', {node: record, action: 'delete', keys: [keys]}

      @return [boolean] delete success indicator
      ###
      _delete: (keys...) ->
        unless keys.length
          error.MissingArgument {name: 'key', argument: 1}

        record = @

        changed = []

        for key, i in keys
          util.isKeyConform key, 1, i

          if not i and contract = record[_OPTIONS].contract
            error.ContractBreak {key, value, contract: contract[key]}

          # prevent idProperty key from getting deleted
          if (id_property = record._idProperty) is key or
          (is_array(id_property) and key in id_property)
            error.Permission
              key:         key
              description: 'idProperty keys can not be deleted'

          if has_own record[_SAVED], key
            if record[_DELETED_KEYS][key]
              continue

            record[_DELETED_KEYS][key] = true

            unless record[_CHANGED_KEYS][key]
              define_value record, _CHANGES, record[_CHANGES] + 1
              define_value record[_CHANGED_KEYS], key, true, 0, 1

            delete record[_EDITED][key]

            Object.defineProperty record, key, enumerable: false
            changed.push key

          else if has_own record, key
            unless is_enumerable record, key
              error.Key {key, description: 'can not be changed'}

            delete record[key]

            if record[_EDITED][key]
              delete record[_EDITED][key]
              define_value record, _CHANGES, record[_CHANGES] - 1
              delete record[_CHANGED_KEYS][key]
            # else it was an ungetterified property

            changed.push key

        if changed.length
          Record.emitUpdate record, 'delete', {keys: changed}

        !!changed.length

      ###
      Getter function that reads a property of the object. Gets the edited state
      from {EditableRecord#._edited} if any, or falls back to the saved state
      stored at {Record#._saved}.

      Returns undefined to properties that are marked as deleted (e.g. were
      deleted by {EditableRecord#_delete} method.

      If found value is an array, it will return a native Array with the values
      instead of the Record instance. Original Record object is available on the
      array's ._record property. See {Record.arrayFilter}.

      @param [number|string] key Property name

      @throw [ArgumentTypeError] Key is missing or is not key conform (string or
        number)

      @return [mixed] value for key
      ###
      _getProperty: (key) ->
        record = @

        value = super

        if record[_DELETED_KEYS][key]
          return
        else if has_own record[_EDITED], key
          return Record.arrayFilter record[_EDITED][key]

        value

      ###
      (Re)define the initial data set (and drop changes)

      @param [object] data Key-value map of data

      Possible errors thrown at {Record#_replace}
      @throw [TypeError] Can not take functions as values
      @throw [KeyError] Keys can not start with underscore

      @event 'update' sends out message on changes:
        events.emit 'update', {node: record, action: 'replace'}

      @return [boolean] indicates change in data
      ###
      _replace: (data) ->
        record = @

        if events = record[_EVENTS]
          events.halt()

        try
          dropped = record._revert 0
          changed = super data, 0
        finally
          if events
            events.unhalt()

        if events and (dropped or changed)
          Record.emitUpdate record, 'replace'

        dropped or changed

      ###
      Return to saved state

      Drops deletions, edited and added properties (if any)

      @param [boolean] emit_event if replace should trigger event emission
        (defaults to true)

      @event 'update' sends out message on changes:
        events.emit 'update', {node: record, action: 'revert'}

      @return [boolean] indicates change in data
      ###
      _revert: (emit_event=true) ->
        changed = false

        record = @
        for key of record[_DELETED_KEYS]
          delete record[_DELETED_KEYS][key]
          delete record[_CHANGED_KEYS][key]
          changed = true

        for key of record[_EDITED]
          delete record[_EDITED][key]
          delete record[_CHANGED_KEYS][key]
          changed = true

        if changed
          define_value record, _CHANGES, 0
          if emit_event
            Record.emitUpdate record, 'revert'

        changed

      ###
      Setter function that writes a property of the object.
      On initialization time (e.g. when called from {Record#_replace} it saves
      values to {Record#._saved}, later it will save to {EditableRecord#_edited}
      or remove property from {EditableRecord#_edited} if reverting to original
      (saved) state.
      Also removes deleted status when setting a property previously marked as
      deleted (by {EditableRecord#_delete} method).

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

      @event 'update' sends out message on changes:
        events.emit {node: record, action: 'set', {key: key}}

      @return [boolean] indication of value change
      ###
      _setProperty: (key, value, initial) ->
        if initial
          return super

        record   = @
        saved    = record[_SAVED]
        edited   = record[_EDITED]
        contract = record[_OPTIONS].contract

        Record.valueCheck record, key, value

        # idProperty values must be string, number or null
        if (id_property = record._idProperty) is key or
        (is_array(id_property) and key in id_property)
          unless value is null or typeof value in ['string', 'number']
            error.Value {value, required: 'string or number or null'}

        value = Record.valueWrap record, key, value

        if util.identical saved[key], value
          delete edited[key]
          changed = 1
        else unless util.identical edited[key], value
          contract?._match key, value

          res = value

          delete_unmatched_keys = ->
            for k of res # delete properties not in the value
              if is_enumerable(res, k) and not has_own value, k
                res._delete k
            return

          if arr = value?[_ARRAY]
            if is_object saved[key]
              res = saved[key]
              if saved_arr = res[_ARRAY]
                for i in [arr.length ... saved_arr.length] by 1
                  saved_arr.pop()
                for item, i in arr[0 ... saved_arr.length]
                  saved_arr[i] = item
                saved_arr.push arr[saved_arr.length ...]...
              else
                delete_unmatched_keys()
                Record.arrayify res
                res[_ARRAY].push arr...
          else if is_object value
            if is_object saved[key]
              res = saved[key]
              if res[_ARRAY]
                Record.dearrayify res
              delete_unmatched_keys()
              for k, v of value
                res._setProperty k, v

          edited[key] = res
          changed = 1

        if record[_DELETED_KEYS][key]
          delete record[_DELETED_KEYS][key]
          changed = 1

        if edited[key] is saved[key]
          delete edited[key]

        was_changed = record[_CHANGED_KEYS][key]

        if (is_object(saved[key]) and saved[key]._changes) or
        (has_own(edited, key) and not util.identical saved[key], edited[key])
          unless was_changed
            define_value record, _CHANGES, record[_CHANGES] + 1
            define_value record[_CHANGED_KEYS], key, true, 0, 1
        else if was_changed
          define_value record, _CHANGES, record[_CHANGES] - 1
          delete record[_CHANGED_KEYS][key]

        Record.getterify record, key

        if changed
          if record[_PARENT_KEY]
            EditableRecord.subChanges record[_PARENT], record[_PARENT_KEY],
                                      record[_CHANGES]

          Object.defineProperty record, key, enumerable: true

          Record.emitUpdate record, 'set', {key}

        !!changed


      ###
      Event handler for child-object data change events
      Also triggers change event call upwards if state of changes gets modified
      in this level.

      @param [object] record reference to record or subrecord object
      @param [string|number] key key on this layer (e.g. parent) record
      @param [number] n number of changes in the child record

      @return [undefined]
      ###
      @subChanges: (record, key, n) ->
        if record[_CHANGED_KEYS][key]
          unless n
            define_value record, _CHANGES, record[_CHANGES] - 1
            delete record[_CHANGED_KEYS][key]
            changed = true
        else if n
          define_value record, _CHANGES, record[_CHANGES] + 1
          define_value record[_CHANGED_KEYS], key, true, 0, 1
          changed = true

        if changed and record[_PARENT_KEY]
          EditableRecord.subChanges record[_PARENT], record[_PARENT_KEY],
                                    record[_CHANGES]
        return
]
