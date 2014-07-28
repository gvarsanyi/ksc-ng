
app.factory 'ksc.Mixin', [
  'ksc.TypeError', 'ksc.Utils',
  (TypeError, Utils) ->

    normalize = (explicit, properties, next) ->
      if explicit?
        unless typeof explicit is 'boolean'
          properties.unshift explicit
          explicit = true

      for property in properties
        unless typeof property in ['string', 'number']
          throw new TypeError property, 'string', 'number'

      next explicit, properties

    validate_key = (extensible, key, explicit, properties) ->
      if Utils.hasProperty extensible, key
        return false

      unless explicit?
        return true

      found = key in properties
      (explicit and found) or (not explicit and not found)


    ###
    Mixin methods

    Extend class instance and/or prototype with properties of an other class.
    Will not override existing properties on the extended class.
    Supports explicit inclusion/exclusion.

    @example
        class A
          @instProp: 'x'
          protoProp: 'y'
          zProp: 'not z here'

        class B
          Mixin.extend B, A

          zProp: 'z'

        console.log B.instProp is 'x'   # true
        console.log B::protoProp is 'y' # true
        console.log B::zProp is 'z' # true

    @author Greg Varsanyi
    ###
    class Mixin

      ###
      Extend both class prototype and instance based on source class prototype
      and instance

      @param [class] extensible class to be extended
      @param [class] mixin extension source class
      @param [boolean] explicit (optional) true = only copy properties named
        explicitly as follows. false = only copy properties that are not in
        the following list. Defaults to true if property names are provided.
      @param [string] properties explicit list of properties to be included or
        excluded from the mixin class (depending on the previous boolean arg)

      @throw [TypeError] a property name in the properties list is not a string

      @return [undefined]
      ###
      @extend: (extensible, mixin, explicit, properties...) ->
        Mixin.extendProto extensible, mixin, explicit, properties...
        Mixin.extendInstance extensible, mixin, explicit, properties...

      ###
      Extend class instance based on source class instance

      @param [class] extensible class to be extended
      @param [class] mixin extension source class
      @param [boolean] explicit (optional) true = only copy properties named
        explicitly as follows. false = only copy properties that are not in
        the following list. Defaults to true if property names are provided.
      @param [string] properties explicit list of properties to be included or
        excluded from the mixin class (depending on the previous boolean arg)

      @throw [TypeError] a property name in the properties list is not a string

      @return [undefined]
      ###
      @extendInstance: (extensible, mixin, explicit, properties...) ->
        normalize explicit, properties, (explicit, properties) ->
          for key, property of mixin
            if validate_key extensible, key, explicit, properties
              extensible[key] = property
          return

      ###
      Extend class prototype based on source class prototype

      @param [class] extensible class to be extended
      @param [class] mixin extension source class
      @param [boolean] explicit (optional) true = only copy properties named
        explicitly as follows. false = only copy properties that are not in
        the following list. Defaults to true if property names are provided.
      @param [string] properties explicit list of properties to be included or
        excluded from the mixin class (depending on the previous boolean arg)

      @throw [TypeError] a property name in the properties list is not a string

      @return [undefined]
      ###
      @extendProto: (extensible, mixin, explicit, properties...) ->
        Mixin.extendInstance extensible.prototype, mixin.prototype,
                             explicit, properties...
]
