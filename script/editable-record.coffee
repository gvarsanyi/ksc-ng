
app.factory 'ksc.EditableRecord', [
  'ksc.ArgumentTypeError', 'ksc.MissingArgumentError', 'ksc.Record',
  'ksc.TypeError', 'ksc.Utils',
  (ArgumentTypeError, MissingArgumentError, Record,
   TypeError, Utils) ->

    ID           = '_id'
    CHANGES      = '_changes'
    CHANGED_KEYS = '_changedKeys'
    DELETED_KEYS = '_deletedKeys'
    EDITED       = '_edited'
    PARENT       = '_parent'
    PARENT_KEY   = '_parentKey'
    SAVED        = '_saved'

    define_value  = Utils.defineValue
    has_own       = Utils.hasOwn
    is_enumerable = Utils.isEnumerable
    is_object     = Utils.isObject


    ###
    Stateful record overrides and extensions

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

      ###
      Create the record instance with initial data and options

      @throw [ArgumentTypeError] option is not an object

      @param [object] data (optional) initital (saved) data set for the record
      @param [object] options (optional) options to define endpoint, contract,
        id key property etc
      @param [object] parent (optional) reference to parent (list or
        parent record)
      @param [number|string] parent_key (optional) parent record's key
      ###
      constructor: (data={}, options={}, parent, parent_key) ->
        unless is_object options
          throw new ArgumentTypeError 'data', 1, data, 'object'
        options.subtreeClass = EditableRecord
        super data, options, parent, parent_key

      # @property [object] dictionary of changed keys
      _changedKeys: null

      # @property [number] number of editions in the data set
      _changes: 0

      # @property [object] dictionary of deleted keys
      _deletedKeys: null

      # @property [object] dictionary of edited keys and new values
      _edited: null


      ###
      Clone record or contents

      @param [boolean] return_plain_object (optional) return a vanilla js Object
      @param [boolean] saved_only (optional) return only saved-state data

      @return [Object/EditableRecord] the new instance with identical data
      ###
      _clone: (return_plain_object=false, saved_only=false) ->
        if saved_only
          return super

        record = @
        if return_plain_object
          clone = {}
          for key, value of record
            if value instanceof Record
              value = value._clone 1
            clone[key] = value
          return clone

        clone = new (record.constructor) record[SAVED]
        for key of record
          if record[CHANGED_KEYS][key] or not has_own record[SAVED], key
            value = record[key]
            if is_object value
              value = value._clone 1
            clone[key] = value
        clone

      ###
      Mark property as deleted, remove it from the object, but keep the original
      data (saved status) for the property.

      @throw [MissingArgumentError] No key was provided
      @throw [ArgumentTypeError] Provided key is not string or number

      @param [string|number] keys... One or more keys to delete

      @return [boolean] delete success indicator
      ###
      _delete: (keys...) ->
        unless keys.length
          throw new MissingArgumentError 'key', 1

        record = @

        if record._options.contract
          return false # can't delete on contracts

        for key, i in keys
          unless typeof key in ['number', 'string']
            throw new ArgumentTypeError 'keys', i + 1, key, 'number', 'string'

          if has_own record[SAVED], key
            unless record[DELETED_KEYS][key]
              record[DELETED_KEYS][key] = true
              @[key] = {}.undef # guaranteed undefined
              Object.defineProperty record, key, enumerable: false
          else if has_own record, key
            if is_enumerable record, key
              delete record[key]
            else
              return false

        true

      # may define setter that calls parent (List) recordIdChanged(record, old)
      _replace: (data) ->
        super

        record = @

        define_value record, EDITED, {}
        define_value record, CHANGES, 0
        define_value record, CHANGED_KEYS, {}
        define_value record, DELETED_KEYS, {}

        for key of record[SAVED]
          EditableRecord.setProperty record, key

        return

      _revert: ->
        @_replace @[SAVED]


      @setProperty: (record, key) ->
        saved    = record[SAVED]
        edited   = record[EDITED]
        options  = record._options
        contract = options.contract

        update_id = -> # update _id if needed
          act = ->
            old_id = record[ID]
            Record.setId record
            record[PARENT]?.recordIdChanged? record, old_id

          if has_own record, ID
            if Array.isArray id_property = options.idProperty
              if id_property.indexOf(key) > -1
                act()
            else if key is id_property
              act()

        getter = ->
          if has_own edited, key
            return edited[key]
          saved[key]

        setter = (update) ->
          if typeof update is 'function'
            throw new TypeError update, 'function', true

          if Utils.identical saved[key], update
            delete edited[key]
          else
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

          if edited[key] is saved[key]
            delete edited[key]

          was_changed = record[CHANGED_KEYS][key]

          if (is_object(saved[key]) and saved[key]._changes) or
          (has_own(edited, key) and not Utils.identical saved[key], edited[key])
            unless was_changed
              define_value record, CHANGES, record[CHANGES] + 1
              define_value record[CHANGED_KEYS], key, true, false, true
          else if was_changed
            define_value record, CHANGES, record[CHANGES] - 1
            delete record[CHANGED_KEYS][key]

          if record[PARENT_KEY]
            EditableRecord.subChanges record[PARENT], record[PARENT_KEY],
                                      record[CHANGES]

          Object.defineProperty record, key, enumerable: true

          update_id()

        # not enumerable if value is undefined
        Utils.defineGetSet record, key, getter, setter, 1

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
]
