
app.factory 'ksc.Utils', ->

  class Utils

    @isObject: (refs...) ->
      for ref in refs
        return false unless ref and typeof ref is 'object'
      true

    @defineGetSet: (obj, key, getter, setter, visible=false) ->
      if typeof setter isnt 'function'
        visible = setter
        setter  = ->

      delete obj[key]
      Object.defineProperty obj, key,
        configurable: true
        enumerable:   !!visible
        get:          getter
        set:          setter

    @defineValue: (obj, key, value, read_only=true, visible=false) ->
      delete obj[key]
      Object.defineProperty obj, key,
        configurable: true
        enumerable:   !!visible
        value:        value
        writable:     !read_only
