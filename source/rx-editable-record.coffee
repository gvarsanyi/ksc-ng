
CalendarCtrl.factory 'RxEditableRecord', [
  'RxRecord',
  (RxRecord) ->

    class RxEditableRecord extends RxRecord
      is_object = (refs...) ->
        for ref in refs
          return false unless ref and typeof ref is 'object'
        true

      _construct: (data) ->
        deep_inherit = (saved, data) ->
          data ?= Object.create saved
          for own k, v of saved when is_object v
            data[k] = deep_inherit v
          data

        saved = super
        saved._base._data = deep_inherit saved

      _changed: (keys...) =>
        recursive_cmp = (data, saved, key_trail=[]) ->
          for own key, value of data
            if is_object value, saved[key]
              (trail = angular.copy key_trail).push key
              recursive_cmp value, saved[key], trail
            else if value isnt saved[key]
              if key_trail.length
                (response = angular.copy key_trail).push key
                changed_keys.push response
              else
                changed_keys.push key

        changed_keys = []
        if keys.length
          for key in keys
            orig_key = key
            data     = @_data
            saved    = @_saved
            if is_object key
              for subkey in key[0 ... key.length - 1]
                if is_object(data) and data[subkey]?
                  data = data[subkey]
                else
                  data = null

                if is_object(saved) and saved[subkey]?
                  saved = saved[subkey]
                else
                  saved = null
              key = key[key.length - 1]

            if is_object data?[key], saved?[key]
              trail = orig_key
              unless is_object orig_key
                trail = [orig_key]
              recursive_cmp data[key], saved[key], trail
            else if data?.hasOwnProperty(key) and
            (not saved?.hasOwnProperty(key) or data[key] isnt saved[key])
              changed_keys.push orig_key
        else
          recursive_cmp @_data, @_saved

        if changed_keys.length
          changed_keys.sort (a, b) ->
            a = a.join('.') if is_object a
            b = b.join('.') if is_object b
            return 1 if a > b
            - 1
          return changed_keys
        false

      _clone: (return_plain_object=false, saved_only=false) ->
        clone = angular.copy @_saved
        angular.copy(@_data, clone) unless saved_only

        unless return_plain_object
          clone = new @constructor angular.copy source

        clone

      _replace: (incoming) ->
        deep_replace = (incoming, saved, data) ->
          for own k, v of saved
            unless is_object v, incoming[k]
              delete saved[k]

          for own k, v of data
            unless is_object v, saved[k]
              delete data[k]

          for k, v of incoming
            if is_object v
              if is_object saved[k]
                deep_replace v, saved[k], data[k]
              else
                saved[k] = v
                data[k] = Object.create saved[k]
            else
              saved[k] = v
          return

        deep_replace angular.copy(incoming), @_saved, @_data

      _revert: ->
        deep_revert = (saved, data) ->
          for own k, v of data
            if is_object saved[k]
              if is_object v
                deep_revert saved[k], v
              else
                data[k] = Object.create saved[k]
            else
              delete data[k]
          return

        deep_revert @_saved, @_data
]
