
app.factory 'ksc.Utils', ->

  arg_check = (args) ->
    unless args.length
      throw new Error '1 or more arguments required'

  class Utils

    @defineGetSet: (obj, key, getter, setter, visible) ->
      if typeof setter isnt 'function'
        visible = setter
        setter  = ->

      Object.defineProperty obj, key,
        configurable: true
        enumerable:   !!visible
        get:          getter
        set:          setter

    @defineValue: (obj, key, value, writable=false, visible=false) ->
      if Object.getOwnPropertyDescriptor(obj, key)?.writable is false
        Object.defineProperty obj, key, writable: true

      Object.defineProperty obj, key,
        configurable: true
        enumerable:   !!visible
        value:        value
        writable:     !!writable

    @hasOwn = (obj, key) ->
      Utils.isObject(obj) and obj.hasOwnProperty key

    @identical: (obj1, obj2) ->
      unless Utils.isObject obj1, obj2
        return obj1 is obj2

      for own k, v1 of obj1
        unless Utils.identical(v1, obj2[k]) and Utils.hasOwn obj2, k
          return false
      for own k of obj2 when not Utils.hasOwn obj1, k
        return false
      true

    @isEnumerable: (obj, key) ->
      try
        return !!(Object.getOwnPropertyDescriptor obj, key).enumerable
      false

    @isFunction: (refs...) ->
      arg_check refs
      for ref in refs
        return false unless ref and typeof ref is 'function'
      true

    @isObject: (refs...) ->
      arg_check refs
      for ref in refs
        return false unless ref and typeof ref is 'object'
      true
