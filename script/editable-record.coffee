
app.factory 'ksc.EditableRecord', [
  'ksc.Record', 'ksc.Utils',
  (Record, Utils) ->

    define_getset = Utils.defineGetSet
    define_value  = Utils.defineValue
    is_object     = Utils.isObject

    has_own = (obj, key) ->
      obj.hasOwnProperty key

    class EditableRecord extends Record
      #_changed: false

      _clone: (return_plain_object=false, saved_only=false) ->
        if saved_only
          return super

        edited = {}
        for key, value of @
          if has_own(@_edited, key) or has_own @_saved, key
            edited[key] = value
        clone = angular.copy edited

        unless return_plain_object
          clone = new @constructor clone

        clone

      _replace: (data) ->
        super

        define_value @, '_edited', {}

        record = @

        identical = (obj1, obj2) ->
          unless is_object v1, v2
            return v1 is v2

          for k, v1 of obj1 when not identical v1, obj2[k]
            return false
          for k of obj2 when not has_own obj1, k
            return false
          true

        deep_rw = (saved, edited, target) ->
          target ?= {}

          s = (key) ->
            getter = ->
              if typeof (res = edited[key]) is 'undefined'
                res = saved[key]
              if is_object res
                return deep_rw saved[key], edited[key]
              res

            setter = (update) ->
              if (is_object(update) and identical(saved[key], update)) or
              saved[key] is update
                delete edited[key]
              else
                edited[key] = update

            define_getset target, key, getter, setter, true

          for key of edited
            s key
          if is_object saved
            for key of saved when not has_own edited, key
              s key

          target

        deep_rw @_saved, @_edited, @

      _revert: ->
        define_value @, '_edited', {}
]
