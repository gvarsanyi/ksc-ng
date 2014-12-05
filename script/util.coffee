
ksc.service 'ksc.util', [
  'ksc.error',
  (error) ->

    define_property             = Object.defineProperty
    get_own_property_descriptor = Object.getOwnPropertyDescriptor
    get_prototype_of            = Object.getPrototypeOf

    arg_check = (args) ->
      unless args.length
        error.MissingArgument {name: 'reference', argument: 1}

    ###
    Miscellaneous utilities that do not belong to other named utility groups
    (like restUtil)

    @author Greg Varsanyi
    ###
    class Util

      ###
      Add/update an object property with a getter and an (optional) setter

      @param [Object] object target object reference
      @param [string|number] key property name on object
      @param [function] getter function that returns value
      @param [function] setter (optional) function that consumes set value
      @param [boolean] enumerable (optional, default: false) if the property
        should be enumerable in a `for key of object` loop

      @return [object] reference to object
      ###
      @defineGetSet: (object, key, getter, setter, enumerable) ->
        if typeof setter isnt 'function'
          enumerable = setter
          setter     = undefined

        define_property object, key,
          configurable: true
          enumerable:   !!enumerable
          get:          getter
          set:          setter

      ###
      Add/update an object property with provided value

      @param [Object] object target object reference
      @param [string|number] key property name on object
      @param [any type] value
      @param [boolean] writable (optional, default: false) read-only if false
      @param [boolean] enumerable (optional, default: false) if the property
        should be enumerable in a `for key of object` loop

      @return [object] reference to object
      ###
      @defineValue: (object, key, value, writable, enumerable) ->
        if get_own_property_descriptor(object, key)?.writable is false
          define_property object, key, writable: true

        define_property object, key,
          configurable: true
          enumerable:   !!enumerable
          value:        value
          writable:     !!writable

      ###
      Helper function that clears Array elements and/or Object properties

      @note For arrays it will pop all the elements
      @note For objects it will delete all owned properties

      @param [Array|Object] objects... Array and/or Object instance(s) to empty

      @return [undefined]
      ###
      @empty: (objects...) ->
        unless objects.length
          error.MissingArgument {argument: 1}
        unless is_object.apply @, objects
          error.Type
            arguments: objects
            required:  'All arguments must be objects'
        for obj in objects
          if Array.isArray obj
            unless fn = obj.pop
              fn = Array::pop
            for i in [0 ... obj.length] by 1
              fn.call obj
          else
            for own key of obj
              delete obj[key]
        return

      ###
      Check if object has own property with provided name and (optionally) if
      it matches enumerability requirement

      @param [Object] object target object reference
      @param [string|number] key property name on object
      @param [boolean] is_enumerable (optional) false: should not be enumerable,
        true: must be enumerable

      @return [boolean] matched
      ###
      @hasOwn: (object, key, is_enumerable) ->
        object and object.hasOwnProperty(key) and
        (not is_enumerable? or is_enumerable is object.propertyIsEnumerable key)

      ###
      Has own property or property on any if its ancestors.

      @param [Object] object target object reference
      @param [string|number] key property name on object

      @return [boolean] matched
      ###
      @hasProperty: (object, key) ->
        while object
          if object.hasOwnProperty key
            return true
          object = get_prototype_of object
        false

      ###
      Check if compared values are identical or if provided objects have equal
      properties and values.

      @param [any type] comparable1
      @param [any type] comparable2

      @return [boolean] identical
      ###
      @identical: (comparable1, comparable2) ->
        unless is_object comparable1, comparable2
          return comparable1 is comparable2

        if comparable1._array
          comparable1 = comparable1._array
        if comparable2._array
          comparable2 = comparable2._array

        for key, v1 of comparable1
          unless Util.identical(v1, comparable2[key]) and
          has_own comparable2, key
            return false
        for key of comparable2 when not has_own comparable1, key
          return false
        true

      ###
      Checks if object property is enumerable

      @param [Object] object target object reference
      @param [string|number] key property name on object

      @return [boolean] property is enumerable
      ###
      @isEnumerable: (object, key) ->
        try
          return !!(get_own_property_descriptor object, key).enumerable
        false

      ###
      Checks if provided key conforms standards and best practices:
      either a non-empty string or a number (not NaN)

      @param [any type] key name/id

      @return [boolean] matches key requirements
      ###
      @isKeyConform: (key) ->
        !!(typeof key is 'string' and key) or
        (typeof key is 'number' and not isNaN key)

      ###
      Checks if refence is or references are all of function type

      @param [any type] refs... values to match

      @return [boolean] all function
      ###
      @isFunction: (refs...) ->
        arg_check refs
        for ref in refs when typeof ref isnt 'function'
          return false
        true

      ###
      Checks if refence is or references are all of object type

      @param [any type] refs... values to match

      @return [boolean] all object
      ###
      @isObject: (refs...) ->
        arg_check refs
        for ref in refs when not ref or typeof ref isnt 'object'
          return false
        true

      ###
      Merge properties from source object(s) to target object

      @param [object] target_object object to be updated
      @param [object] source_objects... Source for new properties/overrides to
        be copied onto target_object

      @return [object] target_object
      ###
      @mergeIn: (target_object, source_objects...) ->
        if source_objects.length < 1
          error.MissingArgument required: 'Merged and mergee objects'
        unless is_object target_object
          error.Type {target_object, argument: 1, required: 'object'}

        for object, i in source_objects
          unless is_object object
            error.Type {object, argument: i + 2, required: 'object'}

          for key, value of object
            target_object[key] = value

        target_object

      ###
      Get all enumerable properties readable on provided object and all its
      ancestors and turn them into key-value maps where values are arrays with
      object references that own the named property.

      @param [Object] object target object reference

      @return [object] map with all keys, values are arrays with references to
        property owner objects
      ###
      @propertyRefs: (object) ->
        properties = {}

        while is_object object
          checked = true
          for own key of object
            unless Array.isArray properties[key]
              properties[key] = []
            properties[key].push object
          object = get_prototype_of object

        unless checked
          error.ArgumentType {object, argument: 1, accepts: 'object'}
        properties

      ###
      Generate simple numeric unique IDs

      For each name (or no name) it starts with 1 and gets incremented by 1 on
      every read

      @param [string|number] name (optional) uid group name

      @return [number] unique integer ID that is >= 1 and unique within the name
        group
      ###
      @uid: (name) ->
        uid_store = (Util._uidStore ?= {named: {}})

        if name?
          unless Util.isKeyConform name
            error.Key {name, requirement: 'Key type name'}

          target = uid_store.named
        else
          target = uid_store
          name = 'unnamed'

        target[name] = (target[name] or 0) + 1


    # resolved names for minification and name resolution performance
    define_value = Util.defineValue
    has_own      = Util.hasOwn
    is_object    = Util.isObject

    Util
]
