
app.factory 'ksc.EditableRecord', [
  'ksc.Record', 'ksc.Utils',
  (Record, Utils) ->

    ID            = '_id'
    CHANGES       = '_changes'
    CHANGED_KEYS  = '_changedKeys'
    DELETED_KEYS  = '_deletedKeys'
    EDITED        = '_edited'
    PARENT        = '_parent'
    PARENT_KEY    = '_parentKey'
    SAVED         = '_saved'
    SUBTREE_CLASS = '_subtreeClass'

    define_value  = Utils.defineValue
    has_own       = Utils.hasOwn
    is_enumerable = Utils.isEnumerable
    is_object     = Utils.isObject

    class EditableRecord extends Record
      constructor: ->
        define_value @, SUBTREE_CLASS, EditableRecord
        define_value @, DELETED_KEYS, {}
        super

      # virtual properties:
      # - _changes: 0
      # - _changedKeys: {}

      _clone: (return_plain_object=false, saved_only=false) ->
        if saved_only
          return super

        record = @
        if return_plain_object
          clone = {}
          for key, value of record when is_enumerable record, key
            if value instanceof Record
              value = value._clone 1
            clone[key] = value
          return clone

        clone = new (record.constructor) record[SAVED]
        for key of record when is_enumerable record, key
          if record[CHANGED_KEYS][key] or not has_own record[SAVED], key
            value = record[key]
            if is_object value
              value = value._clone 1
            clone[key] = value
        clone

      _delete: (keys...) ->
        unless keys.length
          throw new Error 'Key not defined'

        record = @

        for key in keys
          if has_own record[SAVED], key
            unless record[DELETED_KEYS][key]
              record[DELETED_KEYS][key] = true
              @[key] = {}.undef # guaranteed undefined
              Object.defineProperty record, key, enumerable: false
          else if has_own record, key
            if is_enumerable record, key
              delete record[key]
            else
              throw new Error 'Can not remove ' + key

        return

      # may define setter that calls parent (List) recordIdChanged(record, old)
      _replace: (data) ->
        super

        record = @

        define_value record, EDITED, {}
        define_value record, CHANGES, 0
        define_value record, CHANGED_KEYS, {}

        set_property = (key, saved, edited) ->
          update_id = -> # update _id if needed
            if has_own record, ID
              if Array.isArray id_property = record._options.idProperty
                if id_property.indexOf(key) > -1
                  new_id = Record.getId record
              else if key is id_property
                new_id = Record.getId record

              if new_id?
                old_id = record[ID]
                define_value record, ID, Record.getId record
                record[PARENT]?.recordIdChanged? record, old_id

          getter = ->
            if has_own edited, key
              return edited[key]
            saved[key]

          setter = (update) ->
            if typeof update is 'function'
              throw new Error 'Property must not be a function'

            if Utils.identical saved[key], update
              delete edited[key]
            else
              res = update
              if is_object update
                if is_object saved[key]
                  res = saved[key]

                  for k of res # delete properties not in the update
                    if is_enumerable(res, k) and not has_own update, k
                      res._delete k
                else
                  class_ref = record[SUBTREE_CLASS]
                  res = new class_ref {}, null, record, key
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
                define_value record[CHANGED_KEYS], key, true, 1, 1
            else if was_changed
              define_value record, CHANGES, record[CHANGES] - 1
              delete record[CHANGED_KEYS][key]

            if record[PARENT_KEY]
              record[PARENT]._subChanges record[PARENT_KEY], record[CHANGES]

            Object.defineProperty record, key, enumerable: true

            update_id()

          # not enumerable if value is undefined
          Utils.defineGetSet record, key, getter, setter, 1

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
            changed = true
        else if n
          define_value record, CHANGES, record[CHANGES] + 1
          define_value record[CHANGED_KEYS], key, true, 1, 1
          changed = true

        if changed and record[PARENT_KEY]
          record[PARENT]._subChanges record[PARENT_KEY], record[CHANGES]
]
