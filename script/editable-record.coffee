
app.factory 'ksc.EditableRecord', [
  'ksc.Record', 'ksc.errors', 'ksc.utils',
  (Record, errors, utils) ->

    CHANGES      = '_changes'
    CHANGED_KEYS = '_changedKeys'
    DELETED_KEYS = '_deletedKeys'
    EDITED       = '_edited'
    EVENTS       = '_events'
    PARENT       = '_parent'
    PARENT_KEY   = '_parentKey'
    SAVED        = '_saved'

    define_value  = utils.defineValue
    has_own       = utils.hasOwn
    is_enumerable = utils.isEnumerable
    is_object     = utils.isObject


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
    - .options.idProperty
    - .options.subtreeClass

    @author Greg Varsanyi
    ###
    class EditableRecord extends Record

      # @property [object] dictionary of changed keys
      _changedKeys: null

      # @property [number] number of editions in the data set
      _changes: 0

      # @property [object] dictionary of deleted keys
      _deletedKeys: null

      # @property [object] dictionary of edited keys and new values
      _edited: null

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
          throw new errors.ArgumentType options:    options
                                        argument:   2
                                        acceptable: 'object'
        options.subtreeClass = EditableRecord
        super data, options, parent, parent_key

      ###
      Clone record or contents

      @param [boolean] return_plain_object (optional) return a vanilla js Object
      @param [boolean] saved_only (optional) return only saved-state data

      @return [Object|EditableRecord] the new instance with identical data
      ###
      _clone: (return_plain_object=false, saved_only=false) ->
        record = @

        if return_plain_object
          clone = {}
          source = if saved_only then record[SAVED] else record
          for key, value of source
            if value instanceof Record
              value = value._clone true, saved_only
            clone[key] = value
          return clone

        clone = new (record.constructor) record[SAVED]
        unless saved_only
          for key of record
            if record[CHANGED_KEYS][key] or not has_own record[SAVED], key
              value = record[key]
              if is_object value
                value = value._clone true
              clone[key] = value
          if deleted_keys = record[DELETED_KEYS]
            for key of record[DELETED_KEYS]
              clone._delete key
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
          throw new errors.MissingArgument {name: 'key', argument: 1}

        record = @

        changed = []

        for key, i in keys
          unless typeof key in ['number', 'string']
            throw new errors.ArgumentType key:        key
                                          argument:   i + 1
                                          acceptable: ['number', 'string']

          if not i and contract = record._options.contract
            throw new errors.ContractBreak {key, value, contract: contract[key]}

          if has_own record[SAVED], key
            if record[DELETED_KEYS][key]
              continue

            record[DELETED_KEYS][key] = true

            unless record[CHANGED_KEYS][key]
              define_value record, CHANGES, record[CHANGES] + 1
              define_value record[CHANGED_KEYS], key, true, false, true

            delete record[EDITED][key]

            Object.defineProperty record, key, enumerable: false
            changed.push key

          else if has_own record, key
            unless is_enumerable record, key
              throw new errors.Key {key, description: 'can not be changed'}

            delete record[key]
            changed.push key

        if changed.length
          Record.emitUpdate record, 'delete', {keys: changed}

        !!changed.length

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

        if events = record[EVENTS]
          events.halt()
        try
          dropped = record._revert()

          if changed = super
            contract = record._options.contract

            define_value record, EDITED, {}
            define_value record, CHANGES, 0
            define_value record, CHANGED_KEYS, {}
            define_value record, DELETED_KEYS, if contract then null else {}
            define_value record, SAVED, {}

            for key, value of record
              define_value record[SAVED], key, value, false, true
              EditableRecord.setProperty record, key

            Object.freeze record[SAVED]
        finally
          if events
            events.unhalt()

        if dropped or changed
          Record.emitUpdate record, 'replace'

        dropped or changed

      ###
      Return to saved state

      Drops deletions, edited and added properties (if any)

      @event 'update' sends out message on changes:
        events.emit 'update', {node: record, action: 'revert'}

      @return [boolean] indicates change in data
      ###
      _revert: ->
        changed = false

        record = @
        for key of record[DELETED_KEYS]
          delete record[DELETED_KEYS][key]
          delete record[CHANGED_KEYS][key]
          changed = true

        for key of record[EDITED]
          delete record[EDITED][key]
          delete record[CHANGED_KEYS][key]
          changed = true

        for key of record when not has_own record[SAVED], key
          delete record[key]
          changed = true

        if changed
          define_value record, CHANGES, 0
          Record.emitUpdate record, 'revert'

        changed

      ###
      Define getter/setter property on record based on {Record#_saved} and
      {EditableRecord#_edited} and {EditableRecord#_deleted}

      @param [object] record reference to object
      @param [string|number] key on record (and ._saved map)

      @return [undefined]
      ###
      @setProperty: (record, key) ->
        saved    = record[SAVED]
        edited   = record[EDITED]
        options  = record._options
        contract = options.contract

        getter = ->
          if not contract and record[DELETED_KEYS][key]
            return
          if has_own edited, key
            return edited[key]
          saved[key]

        setter = (update) ->
          if typeof update is 'function'
            throw new errors.Type {update, notAcceptable: 'function'}

          if utils.identical saved[key], update
            delete edited[key]
            changed = true
          else unless utils.identical edited[key], update
            contract?._match key, update

            res = update
            if is_object update
              if is_object saved[key]
                res = saved[key]

                for k of res # delete properties not in the update
                  if is_enumerable(res, k) and not has_own update, k
                    res._delete k
              else
                subopts = {}
                if contract
                  subopts.contract = contract[key].contract

                res = new EditableRecord {}, subopts, record, key
              for k, v of update
                res[k] = v

            edited[key] = res
            changed = true

          if edited[key] is saved[key]
            delete edited[key]

          was_changed = record[CHANGED_KEYS][key]

          if (is_object(saved[key]) and saved[key]._changes) or
          (has_own(edited, key) and not utils.identical saved[key], edited[key])
            unless was_changed
              define_value record, CHANGES, record[CHANGES] + 1
              define_value record[CHANGED_KEYS], key, true, false, true
          else if was_changed
            define_value record, CHANGES, record[CHANGES] - 1
            delete record[CHANGED_KEYS][key]

          if changed
            if record[PARENT_KEY]
              EditableRecord.subChanges record[PARENT], record[PARENT_KEY],
                                        record[CHANGES]

            Object.defineProperty record, key, enumerable: true

            Record.emitUpdate record, 'set', {key}

        # not enumerable if value is undefined
        utils.defineGetSet record, key, getter, setter, 1
        return

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
        if record[CHANGED_KEYS][key]
          unless n
            define_value record, CHANGES, record[CHANGES] - 1
            delete record[CHANGED_KEYS][key]
            changed = true
        else if n
          define_value record, CHANGES, record[CHANGES] + 1
          define_value record[CHANGED_KEYS], key, true, false, true
          changed = true

        if changed and record[PARENT_KEY]
          EditableRecord.subChanges record[PARENT], record[PARENT_KEY],
                                    record[CHANGES]
        return
]
