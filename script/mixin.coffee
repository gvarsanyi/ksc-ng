
app.factory 'ksc.Mixin', [
  'ksc.Utils',
  (Utils) ->

    normalize = (explicit, properties, next) ->
      if explicit?
        unless typeof explicit is 'boolean'
          properties.unshift explicit
          explicit = true
      next explicit, properties

    validate_key = (extensible, key, explicit, properties) ->
      if Utils.hasProperty extensible, key
        return false

      unless explicit?
        return true

      found = key in properties
      (explicit and found) or (not explicit and not found)


    class Mixin

      @extend: (extensible, mixin, explicit, properties...) ->
        Mixin.extendProto extensible, mixin, explicit, properties...
        Mixin.extendInstance extensible, mixin, explicit, properties...

      @extendInstance: (extensible, mixin, explicit, properties...) ->
        normalize explicit, properties, (explicit, properties) ->
          for key, property of mixin
            if validate_key extensible, key, explicit, properties
              extensible[key] = property
          return

      @extendProto: (extensible, mixin, explicit, properties...) ->
        Mixin.extendInstance extensible.prototype, mixin.prototype,
                             explicit, properties...
]
