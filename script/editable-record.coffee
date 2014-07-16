
app.factory 'ksc.EditableRecord', [
  'ksc.Record', 'ksc.Utils',
  (Record, Utils) ->

    CHANGES      = '_changes'
    CHANGED_KEYS = '_changedKeys'
    EDITED       = '_edited'
    SAVED        = '_saved'

    define_getset = Utils.defineGetSet
    define_value  = Utils.defineValue
    is_object     = Utils.isObject

    has_own = (obj, key) ->
      is_object(obj) and obj.hasOwnProperty key

    class EditableRecord extends Record
      #_changes: false
      #_changedKeys: false

      _clone: (return_plain_object=false, saved_only=false) ->
        if saved_only
          return super

        if return_plain_object
          clone = {}
          for own key, value of @
            if has_own(@[EDITED], key) or has_own @[SAVED], key
              if is_object value
                value = value._clone 1
              clone[key] = value
          return clone

        clone = new @constructor @[SAVED]
        for key, value of @[EDITED]
          if is_object value
            value = value._clone 1
          clone[key] = value
        clone

      _replace: (data) ->
        super data, EditableRecord

        record = @

        define_value record, EDITED, {}
        define_value record, CHANGES, 0
        define_value record, CHANGED_KEYS, {}

        update_id = ->
          define_value record, '_id', Record.getId record

        set_property = (key, saved, edited) ->
          getter = ->
            if typeof (res = edited[key]) is 'undefined'
              res = saved[key]
            res

          setter = (update) ->
            if typeof update is 'function'
              throw new Error 'Property must not be a function'
            if Utils.identical saved[key], update
              if has_own edited, key
                define_value record, CHANGES, record[CHANGES] - 1
                delete record[CHANGED_KEYS][key]
                delete edited[key]
            else
              res = update
              if is_object update
                if is_object saved[key]
                  res = saved[key]
                else
                  res = new EditableRecord {}, sub: {parent: record, key}
                for k, v of update
                  res[k] = v

              unless has_own edited, key
                define_value record, CHANGES, record[CHANGES] + 1
                define_value record[CHANGED_KEYS], key, true, 1, 1

              edited[key] = res

            if sub = record._options.sub
              sub.parent._subChanges sub.key, record[CHANGES]

            if has_own record, '_id' # update _id if needed
              if Array.isArray id_property = record._options.idProperty
                if id_property.indexOf(key) > -1
                  update_id()
              else if key is id_property
                update_id()

          define_getset record, key, getter, setter, 1

        for key of record[SAVED]
          set_property key, record[SAVED], record[EDITED]

        return

      _revert: ->
        @_replace @[SAVED]

      _subChanges: (key, n) ->
        record = @
        if record[CHANGED_KEYS][key]
          unless n
            define_value record, CHANGES, record[CHANGES] - 1
            delete record[CHANGED_KEYS][key]
        else if n
          define_value record, CHANGES, record[CHANGES] + 1
          define_value record[CHANGED_KEYS], key, true, 1, 1
]
