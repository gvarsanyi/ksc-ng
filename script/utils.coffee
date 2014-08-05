
app.service 'ksc.utils', [
  'ksc.errors',
  (errors) ->

    define_property             = Object.defineProperty
    get_own_property_descriptor = Object.getOwnPropertyDescriptor
    get_prototype_of            = Object.getPrototypeOf

    arg_check = (args) ->
      unless args.length
        throw new errors.MissingArgument {name: 'reference', argument: 1}

    uid_store = named: {}

    utils =
      defineGetSet: (obj, key, getter, setter, visible) ->
        if typeof setter isnt 'function'
          visible = setter
          setter  = ->

        define_property obj, key,
          configurable: true
          enumerable:   !!visible
          get:          getter
          set:          setter

      defineValue: (obj, key, value, writable=false, visible=false) ->
        if get_own_property_descriptor(obj, key)?.writable is false
          define_property obj, key, writable: true

        define_property obj, key,
          configurable: true
          enumerable:   !!visible
          value:        value
          writable:     !!writable

      getProperties: (obj) ->
        properties = {}

        while utils.isObject obj
          checked = true
          for own key of obj
            unless Array.isArray properties[key]
              properties[key] = []
            properties[key].push obj
          obj = get_prototype_of obj

        unless checked
          throw new errors.ArgumentType {obj, argument: 1, acceptable: 'object'}
        properties

      hasOwn: (obj, key, is_enumerable) ->
        obj and obj.hasOwnProperty(key) and
        (not is_enumerable? or is_enumerable is obj.propertyIsEnumerable key)

      hasProperty: (obj, key) ->
        while obj
          if obj.hasOwnProperty key
            return true
          obj = get_prototype_of obj
        false

      identical: (obj1, obj2) ->
        unless utils.isObject obj1, obj2
          return obj1 is obj2

        for k, v1 of obj1
          unless utils.identical(v1, obj2[k]) and utils.hasOwn obj2, k
            return false
        for k of obj2 when not utils.hasOwn obj1, k
          return false
        true

      isEnumerable: (obj, key) ->
        try
          return !!(get_own_property_descriptor obj, key).enumerable
        false

      isKeyConform: (key) ->
        !!(typeof key is 'string' and key) or
        (typeof key is 'number' and not isNaN key)

      isFunction: (refs...) ->
        arg_check refs
        for ref in refs
          return false unless ref and typeof ref is 'function'
        true

      isObject: (refs...) ->
        arg_check refs
        for ref in refs
          return false unless ref and typeof ref is 'object'
        true

      uid: (name) ->
        if name?
          target = uid_store.named
        else
          target = uid_store
          name = 'unnamed'

        target[name] = (target[name] or 0) + 1
]
